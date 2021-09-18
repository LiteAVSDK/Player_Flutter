library demo_super_player_lib;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_player/super_player.dart';

part 'superplayer_observer.dart';
part 'superplayer_controller.dart';
part 'cgi/play_info_parser_v2.dart';
part 'cgi/play_info_parser_v4.dart';
part 'cgi/playinfo_parser.dart';
part 'cgi/playinfo_protocol.dart';
part 'cgi/super_vod_data_loader.dart';
part 'model/superplayer_define.dart';
part 'model/superplayer_model.dart';
part 'tools/video_quality_utils.dart';
part 'ui/superplayer_bottom_view.dart';
part 'ui/superplayer_quality_view.dart';
part 'ui/superplayer_title_view.dart';
part 'ui/superplayer_widget.dart';
part 'common/color_resource.dart';
part 'common/string_resource.dart';