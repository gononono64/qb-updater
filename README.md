<h1>QB Updater</h1>

<p>QB Updater is a resource for FiveM that allows you to update and manage your server resources easily.</p>

<h2>Installation</h2>

<ol>
  <li>Drag and drop the <code>qb-updater</code> folder into your server's resource folder.</li>
  <li>Add <code>start qb-updater</code> to your <code>server.cfg</code> file.</li>
</ol>

<h2>Usage</h2>

<p>QB Updater provides the following commands:</p>

<ul>
  <li>
    <code>/qb-update</code>: Update all qb resources.
    <ul>
      <li>Parameters:</li>
      <ul>
        <li><code>password</code> (optional): The password set in qb-updater. Required if enabled in <code>config.lua</code>.</li>
      </ul>
    </ul>
  </li>
  
  <li>
    <code>/qb-freshupdate</code>: Remove all qb resources and update them.
    <ul>
      <li>Parameters:</li>
      <ul>
        <li><code>password</code> (optional): The password set in qb-updater. Required if enabled in <code>config.lua</code>.</li>
      </ul>
    </ul>
  </li>
  
  <li>
    <code>/qb-install</code>: Download and soft-install GitHub resource.
    <ul>
      <li>Parameters:</li>
      <ul>
        <li><code>url</code>: The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'</li>
        <li><code>branch/password</code> (optional):<br>[Branch] The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') <br> [Password] The password set in qb-updater. Required if enabled in <code>config.lua</code> and the resource is not already installed.</li>
        <li><code>password</code> (optional): The password set in qb-updater. Required if enabled in <code>config.lua</code> and the resource is not already installed.</li>
      </ul>
    </ul>
  </li>
  
  <li>
    <code>/qb-installrelease</code>: Download and soft-install GitHub resource from the latest release.
    <ul>
      <li>Parameters:</li>
      <ul>
        <li><code>url</code>: The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'</li>
        <li><code>branch/password</code> (optional):<br>[Branch] The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') <br> [Password] The password set in qb-updater. Required if enabled in <code>config.lua</code> and the resource is not already installed.</li>
        <li><code>password</code> (optional): The password set in qb-updater. Required if enabled in <code>config.lua</code> and the resource is not already installed.</li>
      </ul>
    </ul>
  </li>
</ul>

<h2>Contributing</h2>

<p>Contributions are welcome! If you find any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request.</p>
