import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;

class PusherSerivce {
  PusherSerivce._privateConstructor();

  static final PusherSerivce _instance = PusherSerivce._privateConstructor();

  factory PusherSerivce() => _instance;

  late PusherKeys _pusherKeys;

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final List<PusherChannel> _listChannel = [];
  bool isConnected = false;

  Future<void> init(PusherKeys pusherInit) async {
    _pusherKeys = pusherInit;
    await _pusher.init(
        apiKey: _pusherKeys.apiKey,
        cluster: _pusherKeys.cluster,
        onEvent: _onEvent,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: _onAuthorizer);

    await _pusher.connect();

    _pusherKeys.setSocketId = await _pusher.getSocketId();
  }

  void dispose() async {
    await Future.forEach(
        _listChannel, (channel) async => channel.unsubscribe());
    _pusher.disconnect();
  }

  /*------------------------ Function Helper ------------------------*/

  void _onEvent(PusherEvent event) {
    debugPrint("onEvent: $event");
  }

  void _onError(String message, int? code, dynamic e) {
    debugPrint("onError: $message code: $code exception: $e");
  }

  // Add channel Subscribe
  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("onSubscriptionSucceeded: $channelName data: $data");
  }

  //use this if you want to be informed of a failed subscription attempt, which you could use, for example,
  //to then attempt another subscription or make a call to a service you use to track errors.
  void _onSubscriptionError(String message, dynamic e) {
    debugPrint("onSubscriptionError: $message Exception: $e");
  }

  //only used with private encrypted channels
  //use this if you want to be notified if any messages fail to decrypt.
  void _onDecryptionFailure(String event, String reason) {
    debugPrint("onDecryptionFailure: $event reason: $reason");
  }

  //Called when a member is added to the presence channel.
  void _onMemberAdded(String channelName, PusherMember member) {
    debugPrint("onMemberAdded: $channelName member: $member");
  }

  //Called when a member is removed to the presence channel.
  void _onMemberRemoved(String channelName, PusherMember member) {
    debugPrint("onMemberRemoved: $channelName member: $member");
  }

  /*
    CONNECTING - the connection is about to attempt to be made
    CONNECTED - the connection has been successfully made
    DISCONNECTING - the connection has been instructed to disconnect and it is just about to do so
    DISCONNECTED - the connection has disconnected and no attempt will be made to reconnect automatically
    RECONNECTING - an attempt is going to be made to try and re-establish the connection
  */
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    isConnected = (currentState == "CONNECTED") ? true : false;
  }

  /*------------------------ Public Function ------------------------*/
  Future<void> subscribeChannel(String channel,
      {Function(PusherEvent event)? onEvent}) async {
    await _pusher
        .subscribe(
      channelName: channel,
      onEvent: (event) => onEvent?.call(event),
    )
        .then((channel) {
      _listChannel.add(channel);
    });
  }

  Future<void> trigger(
      String channelName, String eventName, dynamic data) async {
    /// Trigger event is only for private/presence channels
    /// Requires authChannelEndPoint
    if (_listChannel.isEmpty &&
        !_listChannel
            .map((e) => e.channelName)
            .toList()
            .contains(channelName)) {
      return;
    }

    try {
      _pusher.trigger(PusherEvent(
        channelName: channelName,
        eventName: eventName,
        data: data,
      ));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  dynamic _onAuthorizer(
      String channelName, String socketId, dynamic options) async {
    if (_pusherKeys.authChannelEndPoint == null) {
      throw Exception(
          'authChannelEndPoint is null, if you want to use "private channel" ,"presence channel" requires api authorize from the server');
    }
    if (channelName.startsWith('presence')) {
      // return _onAuthorizerUser(channelName, socketId, options);
      // There is currently no support for presence channel
      throw Exception('Currently no support for presence channel');
    }

    return _onAuthorizerChannel(channelName, socketId, options);
  }

  dynamic _onAuthorizerChannel(
      String channelName, String socketId, dynamic options) async {
    try {
      /* API BE  */
      var url = Uri.parse(_pusherKeys.authChannelEndPoint!);
      final response = await http.post(url,
          headers: {
            'Content-type': 'application/json',
            'Authorization': 'Bearer ${_pusherKeys.customerToken}',
          },
          body:
              jsonEncode({'socket_id': socketId, 'channel_name': channelName}));
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint(e.toString());
    }

    return {};
  }

  //support for presence channel
  // dynamic _onAuthorizerUser(
  //     String channelName, String socketId, dynamic options) async {
  //   try {
  //     /* API BE  */
  //     var url = Uri.parse(_pusherKeys.authUserEndPoint!);
  //     final response = await http.post(url,
  //         headers: {
  //           'Content-type': 'application/json',
  //           'Accept': 'application/json',
  //         },
  //         body: jsonEncode({
  //           'socket_id': socketId,
  //           'channel_name': channelName,
  //           'user_name': 'mrt',
  //         }));
  //     _pusherKeys.setPusherUserId =
  //         jsonDecode(jsonDecode(response.body)['user_data'])["id"] ?? '';
  //     return jsonDecode(response.body);
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }

  //   return {};
  // }
}

class PusherKeys {
// In the next time, apiKey & cluster will be result from BE, or get from .env file
  final String apiKey;
  final String cluster;

  // Send the user's ID token to your server to define
  final String customerToken;
  // Once a private or presence subscription has been authorized
  final String? authChannelEndPoint;

  // // The authEndpoint provides a URL that the Pusher client will call to authorize users for a presence channel.
  // final String? authUserEndPoint;
  // String? _userId;

  //Socketid will be set after init
  String? _socketId;

  PusherKeys({
    required this.apiKey,
    required this.cluster,
    this.authChannelEndPoint,
    required this.customerToken,
  });

  set setSocketId(String socketId) => _socketId = socketId;

  String? get socketId => _socketId;

  // set setPusherUserId(String userId) => _userId = userId;

  // String? get getPusherUserId => _userId;

  static PusherKeys demoPusherInit = PusherKeys(
    apiKey: '1579121763e81d460d93',
    cluster: 'ap1',
    customerToken: "65746jngkrefhgjiker",
    authChannelEndPoint: 'http://192.168.1.20:8000/api/pusher/auth-channel',
  );
}
