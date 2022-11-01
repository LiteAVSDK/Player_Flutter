// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

typedef TaskCallback = void Function(bool success, dynamic result);
typedef TaskDetailFunc = Future Function();

/// 确保入栈的异步/非异步按顺序执行
/// 单线程模型
class TaskExecutors {

  bool _isTaskRunning = false;
  final LinkedList<TaskItem> _taskList = LinkedList<TaskItem>();

  Future addTask(TaskDetailFunc task) {
    Completer completer = Completer();
    TaskItem taskItem = TaskItem(task, (success, result) {
      if (success) {
        completer.complete(result);
      } else {
        completer.completeError(result);
      }
      _isTaskRunning = false;
      //递归任务
      _doTask();
    });
    _taskList.add(taskItem);
    _doTask();
    return completer.future;
  }

  Future<void> _doTask() async {
    if(_isTaskRunning) return;
    if (_taskList.isEmpty) return;
    _isTaskRunning = true;
    TaskItem taskItem = _taskList.first;
    _taskList.remove(taskItem);
    try{
      var result = await taskItem.function.call();
      taskItem.taskCallback.call(true, result);
    } catch(_){
      taskItem.taskCallback.call(false, _.toString());
    }
  }
}

class TaskItem extends LinkedListEntry<TaskItem> {
  TaskDetailFunc function;
  TaskCallback taskCallback;

  TaskItem(this.function, this.taskCallback);
}
