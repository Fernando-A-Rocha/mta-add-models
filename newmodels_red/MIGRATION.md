# Migrating from previous `Newmodels` versions

This article explains how to migrate from previous versions of newmodels to the newest `Newmodels v6 Red 🟥` version.

## Migrating from v4 and v5

It is easy to migrate to v6 from **newmodels v4 and v5**. The **models folder structure remains the same**, but the scripts have changed in the way models are applied to elements.

You just need to migrate your model files (dff, txd, col, etc.) to the new `newmodels_red` resource! They will load and work as before.

## Migrating from v3

Migrating from newmodels v3 is now possible, as the system has now evolved with backwards compatibility in mind. However, some breaking changes have been introduced in v6 that you should be aware of.

### Important changes

This resource no longer uses and relies on the **MTA Element Data system** (`setElementData`) to sync the models to all clients! Instead, newmodels makes use of Lua tables and MTA events. This major change was made to **improve performance** and control the sync of models more efficiently.

### Method

todo
