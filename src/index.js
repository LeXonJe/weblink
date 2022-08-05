const ProtocolRegistry = require("protocol-registry");
const { Logger } = require("tslog");
const makeDir = require("make-dir");
const pause = require("node-pause");
const fs = require("fs");

const logger = new Logger({
  displayLoggerName: false,
  displayFilePath: false,
  displayFunctionName: false,
});

async function main() {
  console.log(
    " _       __     __    __    _       __  \n" +
      "| |     / /__  / /_  / /   (_)___  / /__\n" +
      "| | /| / / _ \\/ __ \\/ /   / / __ \\/ //_/\n" +
      "| |/ |/ /  __/ /_/ / /___/ / / / / ,<   \n" +
      "|__/|__/\\___/_.___/_____/_/_/ /_/_/|_|  \n"
  );

  let config;
  try {
    config = JSON.parse(
      fs.readFileSync("./config.json", { encoding: "utf8", flag: "r" })
    );
  } catch (e) {
    logger.prettyError(e);
    return;
  }

  const path = config.installLocation.replace(
    /%([^%]+)%/g,
    (_, n) => process.env[n]
  );

  if (!fs.existsSync(path)) {
    await makeDir(path);
    logger.info(`Created folder "${path}"`);
  }

  logger.info(`Copying "${config.installScript}" to "${path}"`);

  const destination =
    path + (path.endsWith("\\") ? "" : "\\") + config.installScript;

  try {
    fs.copyFileSync(`./${config.installScript}`, destination);
  } catch (e) {
    logger.prettyError(e);
    return;
  }

  const command = config.command.replace("%location%", destination)

  logger.info(`Registering protocol "${config.protocolName}" with command "${command}"`);

  // Registers the Protocol
  ProtocolRegistry.register(
    {
      protocol: config.protocolName, // sets protocol for your command , testproto://**
      command, // $_URL_ will the replaces by the url used to initiate it
      override: true, // Use this with caution as it will destroy all previous Registrations on this protocol
      terminal: false, // Use this to run your command inside a terminal
      script: false,
    },
    (e) => {
      if (e) {
        logger.prettyError(e);
      } else {
        logger.info("Successfully registered! Press any key to exit...");
      }
    }
  );
}

main();
pause();
