class CommunityPost {
  final int id;
  final String author;
  final String avatar;
  final int daysClean;
  final String text;
  final int likes;
  final int comments;
  final String timeAgo;
  final String? badge;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.avatar,
    required this.daysClean,
    required this.text,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.badge,
  });
}
