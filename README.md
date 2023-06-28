QB Updater is a resource for FiveM that allows you to update and manage your server resources easily.
Installation

    Drag and drop the qb-updater folder into your server's resource folder.
    Add start qb-updater to your server.cfg file.

Usage

QB Updater provides the following commands:

    /qb-update: Update all qb resources.
        Parameters:
            password (optional): The password set in qb-updater. Required if enabled in config.lua.

    /qb-freshupdate: Remove all qb resources and update them.
        Parameters:
            password (optional): The password set in qb-updater. Required if enabled in config.lua.

    /qb-install: Download and soft-install GitHub resource.
        Parameters:
            url: The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'
            branch/password (optional): The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') / [Password] The password set in qb-updater. Required if enabled in config.lua and the resource is not already installed.
            password (optional): The password set in qb-updater. Required if enabled in config.lua and the resource is not already installed.

    /qb-installrelease: Download and soft-install GitHub resource from the latest release.
        Parameters:
            url: The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'
            branch/password (optional): The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') / [Password] The password set in qb-updater. Required if enabled in config.lua and the resource is not already installed.
            password (optional): The password set in qb-updater. Required if enabled in config.lua and the resource is not already installed.

Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request.
