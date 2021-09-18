# Developing Bundles
Developers are invited to develop bundles for others to use. If you already have existing projects on GitHub you can also port them for use by rBundle.

## bundle.json
The `bundle.json` file is quite literally the only difference between a normal GitHub repository and a bundle repository. It's a top level file that provides rBundle with information about the bundle.

The file contains the following information in JSON format:

- `name`: Bundle name (e.g. `Testing`)
- `id`: A string id for the bundle (e.g. `testing`)
- `version`: The version of the bundle as a string (e.g. `1.0.0`)
- `src`: A path to the source directory rBundle will install (e.g. `src`)
- `description`: An optional description for the bundle (e.g. `My bundle`)

Here's a complete example from [this bundle](https://github.com/astrealRBLX/volt) (astrealrblx/volt).

```json
{
  "name": "Volt",
  "id": "volt",
  "description": "A game framework centered around execution flow and modular code",
  "version": "1.1.0",
  "src": "Volt"
}
```