import xarray as xr


def test_netcdf():
    fk = "test.nc"
    ds = xr.Dataset(
        coords={"nx": [0], "ny": [0]},
        attrs={
            "source": "satpy unit test",
            "time_coverage_start": "0001-01-01T00:00:00Z",
            "time_coverage_end": "0001-01-01T01:00:00Z",
        }
    )
    ds.to_netcdf(fk)
