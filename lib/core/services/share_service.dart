import 'package:share_plus/share_plus.dart';

import '../config/share_links.dart';

class ShareService {
  const ShareService();

  Future<void> sharePost({required int postId}) async {
    final url = teenplePostShareUrl(postId);
    final text = 'TeenPle에서 게시글을 확인해보세요.\n$url';

    await Share.share(text, subject: 'TeenPle');
  }
}
