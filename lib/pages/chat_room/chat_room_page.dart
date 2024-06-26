import 'package:child_goods_store_flutter/blocs/chat/room/chat_room_bloc.dart';
import 'package:child_goods_store_flutter/blocs/chat/room/chat_room_event.dart';
import 'package:child_goods_store_flutter/blocs/chat/room/chat_room_state.dart';
import 'package:child_goods_store_flutter/constants/gaps.dart';
import 'package:child_goods_store_flutter/constants/sizes.dart';
import 'package:child_goods_store_flutter/constants/strings.dart';
import 'package:child_goods_store_flutter/enums/loading_status.dart';
import 'package:child_goods_store_flutter/pages/chat_room/widgets/chat_box.dart';
import 'package:child_goods_store_flutter/pages/chat_room/widgets/chat_send_box.dart';
import 'package:child_goods_store_flutter/widgets/app_font.dart';
import 'package:child_goods_store_flutter/widgets/app_ink_button.dart';
import 'package:child_goods_store_flutter/widgets/common/item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTapMore() {
    _unfocus();
  }

  void _scrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.offset >=
          _scrollController.position.maxScrollExtent) {
        _getChats();
      }
    });
  }

  void _getChats({bool force = false}) {
    var bloc = context.read<ChatRoomBloc>();
    if (bloc.state.chatStatus != ELoadingStatus.error || force) {
      bloc.add(ChatRoomGetChats());
    }
  }

  void _onTapRetryGetItem() {
    context.read<ChatRoomBloc>().add(ChatRoomGetItem());
  }

  void _onTapRetryChatConnect() {
    context.read<ChatRoomBloc>().add(ChatRoomInitStomp());
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: _onTapMore,
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
          title: BlocBuilder<ChatRoomBloc, ChatRoomState>(
            buildWhen: (previous, current) =>
                previous.targetStatus != current.targetStatus,
            builder: (context, state) {
              if (state.targetStatus == ELoadingStatus.error) {
                return const AppFont('채팅');
              }
              return SizedBox(
                height: Sizes.size56,
                child: ItemCard(
                  type: state.targetStatus == ELoadingStatus.loaded
                      ? context.read<ChatRoomBloc>().type
                      : null,
                  product: state.targetProduct,
                  together: state.targetTogether,
                  isLarge: false,
                ),
              );
            },
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            reverse: true,
            slivers: [
              // body
              BlocConsumer<ChatRoomBloc, ChatRoomState>(
                listener: (context, state) {
                  if (state.chatStatus == ELoadingStatus.loaded) {
                    _scrollListener();
                  }
                },
                builder: (context, state) {
                  if (state.targetStatus == ELoadingStatus.error) {
                    return SliverFillRemaining(
                      child: _buildError(
                        message: state.targetErrMessage ?? Strings.unknownFail,
                        onRetry: _onTapRetryGetItem,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      bottom: Sizes.size60,
                      right: Sizes.size10,
                      left: Sizes.size10,
                    ),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) => SizedBox(
                        width: double.infinity,
                        child: ChatBox(
                          chats: state.chats,
                          index: index,
                        ),
                      ),
                      separatorBuilder: (context, index) => Gaps.v5,
                      itemCount: state.chats.length,
                    ),
                  );
                },
              ),
              // Loading indicator
              SliverToBoxAdapter(
                child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
                  builder: (context, state) {
                    if (state.targetStatus == ELoadingStatus.error) {
                      return const SizedBox();
                    }
                    if (state.chatStatus == ELoadingStatus.error) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: Sizes.size20),
                        child: _buildError(
                          message: state.chatErrMessage ?? Strings.unknownFail,
                          onRetry: () => _getChats(force: true),
                        ),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: Sizes.size20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomSheet: SafeArea(
          child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
            buildWhen: (previous, current) =>
                previous.targetStatus != current.targetStatus ||
                previous.stompStatus != current.stompStatus,
            builder: (context, state) {
              if (state.targetStatus != ELoadingStatus.loaded) {
                return const SizedBox();
              }
              if (state.stompStatus == ELoadingStatus.loaded) {
                return const ChatSendBox();
              }
              if (state.stompStatus == ELoadingStatus.error) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: Sizes.size1 / 2,
                        spreadRadius: Sizes.size1 / 2,
                        offset: const Offset(0, -Sizes.size2),
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ],
                  ),
                  child: AppInkButton(
                    onTap: _onTapRetryChatConnect,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.transparent,
                    shadowColor: Colors.transparent,
                    child: const AppFont(
                      '채팅서버 연결에 실패했습니다.\n터치하여 재 연결을 시도해주세요.',
                      textAlign: TextAlign.center,
                      fontSize: Sizes.size12,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError({
    required String message,
    required Function() onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFont(message),
          Gaps.v20,
          AppInkButton(
            onTap: onRetry,
            child: const AppFont(
              '재시도',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
