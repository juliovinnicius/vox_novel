package com.example.vox_novel

import com.ryanheise.audioservice.AudioServiceActivity

// A plain FlutterActivity does not expose the engine the background media
// service attaches to, so speech would stop with the activity.
class MainActivity : AudioServiceActivity()
