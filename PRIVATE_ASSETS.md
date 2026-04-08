# Private Assets

Sensitive local data and private branding assets now belong under `PrivateAssets/`, which is ignored by Git.

The current local branding backup path is:

- `PrivateAssets/Branding/GAMELIFE/Assets.xcassets/`

The tracked asset catalog now contains neutral placeholder PNGs so the project can stay buildable without publishing private logos/images.

If you want to restore your local branding after cloning on another machine, copy the backed-up PNGs from `PrivateAssets/Branding/GAMELIFE/Assets.xcassets/` back into `GAMELIFE/Assets.xcassets/`.
