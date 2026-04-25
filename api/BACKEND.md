## API Backend

Start the API from the `api` directory:

```powershell
cd api
python -m app
```

Optional: recreate database tables on startup:

```powershell
cd api
python -m app --drop-all
```

`--drop-all` drops all existing tables and creates them again.