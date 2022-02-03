# WebLink

A small tool to register a simple URL Handler that executes a script.
(Currently only tested on Windows)

## Getting Started

```sh
git clone https://github.com/LeXonJe/weblink
yarn install
```

Then create a config file like that:

```json
{
  "protocolName": "testProt",
  "installScript": "example.bat",
  "installLocation": "%localappdata%\\scripts\\"
}
```

And now you can start and test the script.

```sh
yarn start
```

## Building

```sh
yarn build
```

Then bundle your .exe from the dist folder with the config and a script (aka. put them in the same folder). Done!
