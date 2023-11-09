// Copyright (c) 2022 Tencent. All rights reserved.
library SuperPlayer;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:synchronized/synchronized.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'Core/superplayer_plugin.dart';
part 'Core/tools/log_utils.dart';
part 'Core/txliveplayer_controller.dart';
part 'Core/txplayer_controller.dart';
part 'Core/txplayer_define.dart';
part 'Core/txplayer_widget.dart';
part 'Core/txvodplayer_config.dart';
part 'Core/txvodplayer_controller.dart';
part 'Core/txvoddownload_controller.dart';
part 'Core/txliveplayer_config.dart';
part 'Core/tools/common_utils.dart';
part 'Core/provider/txplayer_holder.dart';
part 'Core/txplayer_messages.dart';
part 'Core/common/common_config.dart';
part 'Core/common/tx_extension.dart';