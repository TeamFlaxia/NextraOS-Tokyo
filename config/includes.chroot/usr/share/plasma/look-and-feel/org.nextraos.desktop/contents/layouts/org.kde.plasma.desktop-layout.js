var plasma = getApiVersion(1);

// Bottom panel
var panel = new Panel;
panel.location = "bottom";
panel.height = Math.round(gridUnit * 2.4);
panel.hiding = "none";
panel.alignment = "left";
panel.lengthMode = "fill";

// App Launcher
panel.addWidget("org.kde.plasma.kickoff");

// Pager
panel.addWidget("org.kde.plasma.pager");

// Task Manager with default pinned launchers
var taskmanager = panel.addWidget("org.kde.plasma.icontasks");
taskmanager.currentConfigGroup = ["General"];
taskmanager.writeConfig("launchers",
    "preferred://browser," +
    "applications:org.kde.dolphin.desktop," +
    "applications:org.kde.systemsettings.desktop"
);

// Margins separator
panel.addWidget("org.kde.plasma.marginsseparator");

// System Tray
panel.addWidget("org.kde.plasma.systemtray");

// Clock
panel.addWidget("org.kde.plasma.digitalclock");

// Show Desktop
panel.addWidget("org.kde.plasma.showdesktop");
