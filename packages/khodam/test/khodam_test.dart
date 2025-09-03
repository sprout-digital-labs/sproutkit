// import 'package:flutter_test/flutter_test.dart';
// import 'package:khodam/khodam.dart';
// import 'package:khodam/khodam_platform_interface.dart';
// import 'package:khodam/khodam_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockKhodamPlatform
//     with MockPlatformInterfaceMixin
//     implements KhodamPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final KhodamPlatform initialPlatform = KhodamPlatform.instance;
//
//   test('$MethodChannelKhodam is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelKhodam>());
//   });
//
//   test('getPlatformVersion', () async {
//     Khodam khodamPlugin = Khodam();
//     MockKhodamPlatform fakePlatform = MockKhodamPlatform();
//     KhodamPlatform.instance = fakePlatform;
//
//     expect(await khodamPlugin.getPlatformVersion(), '42');
//   });
// }
