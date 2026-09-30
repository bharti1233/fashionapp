import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/supabase/supabase_tables.dart';
import 'package:t_store/features/notifications/data/models/notification_model.dart';
import 'package:t_store/features/notifications/domain/entities/notification_entity.dart';
import 'package:t_store/features/notifications/domain/repositories/notification_repository.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseService supabaseService;
  StreamController<NotificationEntity>? _notificationsController;

  NotificationRepositoryImpl({required this.supabaseService});

  String get _userId => supabaseService.currentUser?.id ?? '';

  @override
  Future<Either<String, List<NotificationEntity>>> getNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (_userId.isEmpty) {
        return const Left('Please sign in first');
      }

      final from = page * limit;
      final to = from + limit - 1;

      final response = await supabaseService.client
          .from(SupabaseTables.notifications)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .range(from, to);

      final notifications = (response as List)
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Right(notifications);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications getNotifications failed',
        category: LogCategory.notifications,
        event: 'GET_NOTIFICATIONS_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'getNotifications',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> markAsRead(String notificationId) async {
    try {
      await supabaseService.client
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', _userId);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications markAsRead failed',
        category: LogCategory.notifications,
        event: 'MARK_AS_READ_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'markAsRead',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> markAllAsRead() async {
    try {
      await supabaseService.client
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('user_id', _userId)
          .eq('is_read', false);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications markAllAsRead failed',
        category: LogCategory.notifications,
        event: 'MARK_ALL_AS_READ_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'markAllAsRead',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteNotification(String notificationId) async {
    try {
      await supabaseService.client
          .from(SupabaseTables.notifications)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _userId);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications deleteNotification failed',
        category: LogCategory.notifications,
        event: 'DELETE_NOTIFICATION_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'deleteNotification',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteAllNotifications() async {
    try {
      await supabaseService.client
          .from(SupabaseTables.notifications)
          .delete()
          .eq('user_id', _userId);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications deleteAllNotifications failed',
        category: LogCategory.notifications,
        event: 'DELETE_ALL_NOTIFICATIONS_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'deleteAllNotifications',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> getUnreadCount() async {
    try {
      if (_userId.isEmpty) {
        return const Right(0);
      }

      final response = await supabaseService.client
          .from(SupabaseTables.notifications)
          .select('id')
          .eq('user_id', _userId)
          .eq('is_read', false);

      return Right((response as List).length);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        message: 'Notifications getUnreadCount failed',
        category: LogCategory.notifications,
        event: 'GET_UNREAD_COUNT_FAILURE',
        screen: 'NotificationsRepository',
        operation: 'getUnreadCount',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Stream<NotificationEntity> get notificationsStream {
    if (_userId.isEmpty) {
      return Stream.empty();
    }

    _notificationsController?.close();
    _notificationsController = StreamController<NotificationEntity>.broadcast();

    supabaseService.client
        .from(SupabaseTables.notifications)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .listen((data) {
          for (final item in data) {
            _notificationsController?.add(NotificationModel.fromJson(item));
          }
        });

    return _notificationsController!.stream;
  }
}
