package com.lucentdread.stash_android

import androidx.core.content.FileProvider

/// Own subclass so the manifest entry cannot clash with a plugin's provider.
class UpdateFileProvider : FileProvider()
