/// Exception thrown when a user attempts to create an entry
/// but has exceeded their free entry limit and is not a pro subscriber.
class EntryLimitException implements Exception {
  final String message;
  final int limit;

  EntryLimitException({
    this.message =
        'Free entry limit reached. Upgrade to Pro to create unlimited entries.',
    this.limit = 2,
  });

  @override
  String toString() => 'EntryLimitException: $message (limit: $limit)';
}
