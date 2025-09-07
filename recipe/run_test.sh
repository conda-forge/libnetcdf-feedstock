nc-config --has-dap      | grep -q yes
nc-config --has-dap2     | grep -q yes
nc-config --has-dap4     | grep -q yes
nc-config --has-nc2      | grep -q yes
nc-config --has-nc4      | grep -q yes
nc-config --has-hdf5     | grep -q yes
#nc-config --has-hdf4     | grep -q yes
nc-config --has-cdf5     | grep -q yes

# C++ and Fortran are now separate packages (netcdf-cxx4 and netcdf-fortran)
# nc-config --has-c++      | grep -q no
# nc-config --has-c++4     | grep -q no
# nc-config --has-fortran  | grep -q no

# Parallel is the one we would like to have.
# nc-config --has-parallel | grep -q no

# Not sure if people still uses pnetcdf.
# nc-config --has-pnetcdf  | grep -q no

# We cannot package szip due to its license
# nc-config --has-szlib    | grep -q no

# Minimal NCZarr zip smoke test: create a tiny Zarr store and read it back
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT

cat >"${tmpdir}/mini.cdl" <<'CDL'
netcdf mini {
dimensions:
		x = 3 ;
variables:
		int v(x) ;
data:
		v = 1, 2, 3 ;
}
CDL

# Create a Zarr zip using ncgen via URL mode fragment
zstore="file://${tmpdir}/mini.zip#mode=xarray,zip"
ncgen -o "${zstore}" "${tmpdir}/mini.cdl"

# Ensure ncdump can read the header from the zip-backed Zarr store
if ! ncdump -h "${zstore}" >/dev/null 2>&1; then
	echo "NCZarr zip smoke test failed; emitting diagnostics..." >&2
	NCOPTIONS=warn,open,dispatch,ncmpath ncdump -h "${zstore}" || true
	exit 1
fi

# Verify type detection; some builds may report 'zarr' (extended) or 'netCDF-4' (data model)
kind_zip=$(ncdump -k "${zstore}" || true)
echo "NCZarr zip: ncdump -k => ${kind_zip}"
if ! echo "${kind_zip}" | grep -Eqi 'zarr|netCDF-4'; then
	echo "NCZarr zip: unexpected ncdump -k output: ${kind_zip}" >&2
	exit 1
fi

# Also check directory-backed Zarr for completeness
zdir="file://${tmpdir}/mini.file#mode=xarray,file"
ncgen -o "${zdir}" "${tmpdir}/mini.cdl"
if ! ncdump -h "${zdir}" >/dev/null 2>&1; then
	echo "NCZarr file provider smoke test failed; emitting diagnostics..." >&2
	NCOPTIONS=warn,open,dispatch,ncmpath ncdump -h "${zdir}" || true
	exit 1
fi

kind_file=$(ncdump -k "${zdir}" || true)
echo "NCZarr file: ncdump -k => ${kind_file}"
if ! echo "${kind_file}" | grep -Eqi 'zarr|netCDF-4'; then
	echo "NCZarr file: unexpected ncdump -k output: ${kind_file}" >&2
	exit 1
fi

echo "NCZarr zip and file smoke tests passed"

# On Linux, ensure libnetcdf operations do not emit "getfattr: not found"
# which is noise from DAOS detection when the attr package is missing.
if [[ "$(uname)" == "Linux" ]]; then
	# getfattr should be present via 'attr'
	# Log PATH and where getfattr is coming from to aid diagnosis
	echo "PATH during test: $PATH"
	getfattr_path=$(command -v getfattr || true)
	echo "getfattr path: ${getfattr_path:-NOT FOUND}"
	if [[ -n "${getfattr_path:-}" ]]; then
		# Show details of the resolved binary (if any)
		ls -l "${getfattr_path}" || true
		# Ensure we are using the conda-forge provided binary, not the system one.
		# This guards against silently passing because /usr/bin/getfattr is present.
		case "$getfattr_path" in
			"$PREFIX"/bin/*)
				;;
			*)
				echo "getfattr is not from conda PREFIX: $getfattr_path" >&2
				echo "Expected $PREFIX/bin/getfattr (ensure attr is a runtime dep)." >&2
				exit 1
				;;
		esac
	else
		echo "getfattr not found on PATH; expected from attr runtime dep" >&2
		exit 1
	fi

	# Create a tiny NetCDF-4 file and run ncdump -h, capturing stderr
	cat >"${tmpdir}/mini_nc4.cdl" <<'CDL'
netcdf mini_nc4 {
dimensions:
		x = 1 ;
variables:
		int v(x) ;
}
CDL
	ncgen -k netCDF-4 -o "${tmpdir}/mini_nc4.nc" "${tmpdir}/mini_nc4.cdl"
	# Capture stderr (and stdout) from ncdump to detect any noisy warnings.
	# Note: capturing both keeps this simple and is robust across shells.
	msg=$(ncdump -h "${tmpdir}/mini_nc4.nc" 2>&1 || true)
	if echo "$msg" | grep -q "getfattr: not found"; then
		echo "Unexpected 'getfattr: not found' in ncdump output" >&2
		exit 1
	fi
fi
