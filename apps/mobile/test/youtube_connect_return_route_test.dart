import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/navigation/youtube_connect_return_route.dart';

void main() {
  test('accepts only the exact token-free MoolSocial YouTube return', () {
    expect(
      youtubeConnectReturnLocation(
        'moolsocial://app/creator/youtube-connect'
        '?youtubeConnect=complete',
      ),
      '/app/creator/youtube-connect?youtubeConnect=complete',
    );
    expect(
      youtubeConnectReturnLocation(
        'moolsocial://app/creator/youtube-connect'
        '?youtubeConnect=failed',
      ),
      '/app/creator/youtube-connect?youtubeConnect=failed',
    );
    expect(
      youtubeConnectReturnLocation(
        'https://moolsocial.com/app/creator/youtube-connect'
        '?youtubeConnect=complete',
      ),
      '/app/creator/youtube-connect?youtubeConnect=complete',
    );
  });

  test('rejects secrets, unknown results, origins and routes', () {
    for (final route in <String>[
      'moolsocial://app/creator/youtube-connect'
          '?youtubeConnect=complete&code=secret',
      'moolsocial://app/creator/youtube-connect'
          '?youtubeConnect=complete&youtubeConnect=failed',
      'moolsocial://app/creator/youtube-connect'
          '?youtubeConnect=complete#state',
      'moolsocial://app/creator/youtube-connect'
          '?youtubeConnect=unknown',
      'https://example.com/app/creator/youtube-connect'
          '?youtubeConnect=complete',
      'moolsocial://app/social?youtubeConnect=complete',
    ]) {
      expect(youtubeConnectReturnLocation(route), isNull, reason: route);
    }
  });
}
