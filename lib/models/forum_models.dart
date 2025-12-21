// lib/models/forum_models.dart

class Thread {
  final int id;
  final String title;
  final String content;
  final ThreadAuthor author;
  final List<Tag> tags;
  final String createdAt;
  final int upvotes;
  final int downvotes;
  final int score;
  final int replyCount;
  final bool hasUpvoted;
  final bool hasDownvoted;
  final List<Reply>? replies; // Optional, hanya ada di detail
  final bool isAuthor; // Apakah current user adalah author thread

  Thread({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.tags,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.replyCount,
    required this.hasUpvoted,
    required this.hasDownvoted,
    this.replies,
    this.isAuthor = false,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    List<Tag> tagsList = [];
    if (json['tags'] != null) {
      tagsList = (json['tags'] as List).map((tag) => Tag.fromJson(tag)).toList();
    }

    List<Reply>? repliesList;
    if (json['replies'] != null) {
      repliesList = (json['replies'] as List).map((reply) => Reply.fromJson(reply)).toList();
    }

    return Thread(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: ThreadAuthor.fromJson(json['author']),
      tags: tagsList,
      createdAt: json['created_at'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      score: json['score'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      hasUpvoted: json['has_upvoted'] ?? false,
      hasDownvoted: json['has_downvoted'] ?? false,
      replies: repliesList,
      isAuthor: json['is_author'] ?? false,
    );
  }
}

class ThreadAuthor {
  final int? id;
  final String username;

  ThreadAuthor({this.id, required this.username});

  factory ThreadAuthor.fromJson(Map<String, dynamic> json) {
    return ThreadAuthor(
      id: json['id'],
      username: json['username'] ?? 'Anonymous',
    );
  }
}

class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Reply {
  final int id;
  final String content;
  final ThreadAuthor author;
  final String createdAt;
  final int upvotes;
  final int downvotes;
  final int score;
  final bool hasUpvoted;
  final bool hasDownvoted;

  Reply({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.hasUpvoted,
    required this.hasDownvoted,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      content: json['content'],
      author: ThreadAuthor.fromJson(json['author']),
      createdAt: json['created_at'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      score: json['score'] ?? 0,
      hasUpvoted: json['has_upvoted'] ?? false,
      hasDownvoted: json['has_downvoted'] ?? false,
    );
  }
}

