
library SuperPlayer;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'Core/txliveplayer_controller.dart';
part 'Core/txvodplayer_controller.dart';
part 'Core/txplayer_define.dart';
part 'Core/superplayer_plugin.dart';
part 'Core/txplayer_widget.dart';
part 'Core/txplayer_controller.dart';
part 'Core/txvodplayer_config.dart';
part 'Core/tools/video_quality_utils.dart';
part 'Core/tools/log_utils.dart';
part 'Core/superplayer/cgi/super_vod_data_loader.dart';
part 'Core/superplayer/cgi/play_info_parser_v2.dart';
part 'Core/superplayer/cgi/play_info_parser_v4.dart';
part 'Core/superplayer/cgi/playinfo_parser.dart';
part 'Core/superplayer/cgi/playinfo_protocol.dart';
part 'Core/superplayer/superplater_observer.dart';
part 'Core/superplayer/superplayer_controller.dart';
part 'Core/superplayer/model/superplayer_define.dart';
part 'Core/superplayer/model/superplayer_model.dart';
part 'Core/superplayer/ui/superplayer_widget.dart';
part 'Core/superplayer/ui/superplayer_bottom_view.dart';
part 'Core/superplayer/ui/superplayer_quality_view.dart';
part 'Core/superplayer/ui/superplayer_title_view.dart';
part 'Core/common/string_resource.dart';
part 'Core/common/color_resource.dart';