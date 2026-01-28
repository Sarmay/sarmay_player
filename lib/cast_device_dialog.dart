// 投屏设备选择对话框
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sarmay_player/other_data.dart';
import 'package:media_cast_dlna_2/media_cast_dlna.dart';

class CastDeviceDialog extends StatefulWidget {
  final String playUrl;
  final Duration? tipTime;
  final Widget? castWidget;
  final DevicesType devicesType;
  final VoidCallback onClose;

  const CastDeviceDialog({
    super.key,
    required this.playUrl,
    this.tipTime,
    this.castWidget,
    required this.devicesType,
    required this.onClose,
  });

  @override
  State<CastDeviceDialog> createState() => _CastDeviceDialogState();
}

class _CastDeviceDialogState extends State<CastDeviceDialog> {
  // 投屏相关
  final _api = MediaCastDlnaApi();
  List<DlnaDevice> _devices = [];
  DlnaDevice? _selectedDevice;
  bool _isDiscovering = false;
  bool _isCasting = false; // 正在投屏
  Timer? _discoveryTimer;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _stopDiscovery();
    super.dispose();
  }

  // 初始化DLNA服务
  Future<void> _initializePlugin() async {
    try {
      await _api.initializeUpnpService();
      if (kDebugMode) {
        print('✅ Media Cast DLNA initialized successfully');
      }
      // Check if service is ready
      bool isReady = await _api.isUpnpServiceInitialized();
      if (!isReady) {
        await _api.isUpnpServiceInitialized();
      }
      _startDiscovery();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Initialization failed: $e');
      }
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(left: 8, right: 8),
          child: Column(children: _columnChild()),
        ),
      ),
    );
  }

  List<Widget> _columnChild() {
    if (widget.tipTime != null) {
      return [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.cast, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '选择投屏设备',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        if (widget.castWidget != null) widget.castWidget! else Text("默认提示信息"),
      ];
    }

    return [
      // 标题栏
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.cast, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              '选择投屏设备',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),

      // 搜索状态指示器
      if (_isDiscovering)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.blue[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text(
                '正在搜索设备...',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ],
          ),
        ),

      // 设备列表
      Expanded(child: _buildDeviceList()),

      // 底部按钮
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_isDiscovering)
              ElevatedButton.icon(
                icon: const Icon(Icons.stop, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label: const Text(
                  '停止搜索',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _stopDiscovery,
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  '重新搜索',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                onPressed: _refreshDevices,
              ),
            const Spacer(),
            if (_selectedDevice != null && !_isCasting)
              ElevatedButton.icon(
                icon: const Icon(Icons.cast, size: 20, color: Colors.white),
                label: const Text(
                  '开始投屏',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _startCasting,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (_isCasting)
              ElevatedButton.icon(
                icon: const Icon(Icons.stop, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label: const Text(
                  '停止投屏',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _stopCasting,
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDeviceList() {
    if (_isDiscovering && _devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在搜索设备...'),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('未发现投屏设备'),
            SizedBox(height: 8),
            Text('请确保设备在同一WiFi网络下', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isRenderer = device.deviceType.contains('MediaRenderer');
        final isSelected = device.udn == _selectedDevice?.udn;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isSelected ? Colors.blue[50] : Colors.white,
          elevation: 1,
          child: ListTile(
            leading: Icon(
              isRenderer ? Icons.live_tv : Icons.music_video,
              color: isRenderer ? Colors.blue : Colors.orange,
              size: 32,
            ),
            title: Text(
              device.friendlyName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${device.manufacturerDetails.manufacturer} • ${device.ipAddress.value}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isRenderer
                ? Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.green : Colors.grey,
                  )
                : const Icon(Icons.cancel, color: Colors.orange),
            selected: isSelected,
            onTap: isRenderer ? () => _selectDevice(device) : null,
          ),
        );
      },
    );
  }

  // 选择设备
  void _selectDevice(DlnaDevice device) {
    setState(() {
      _selectedDevice = device;
    });
  }

  // 开始投屏
  Future<void> _startCasting() async {
    if (_selectedDevice == null) return;

    try {
      final metadata = VideoMetadata(
        title: '视频播放',
        duration: TimeDuration(seconds: 0),
        resolution: '1920x1080',
        genre: 'Video',
        upnpClass: 'object.item.videoItem.movie',
      );

      await _api.setMediaUri(
        _selectedDevice!.udn,
        Url(value: widget.playUrl),
        metadata,
      );

      await _api.play(_selectedDevice!.udn);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已投屏到 ${_selectedDevice!.friendlyName}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isCasting = true;
        });
        widget.onClose();
      }
    } catch (e) {
      if (kDebugMode) {
        print('投屏失败: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('投屏失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCasting = false;
        });
      }
    }
  }

  // 停止投屏
  Future<void> _stopCasting() async {
    if (_selectedDevice != null) {
      try {
        await _api.stop(_selectedDevice!.udn);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已停止投屏'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('停止投屏失败: $e');
        }
      }
    }
    widget.onClose();
  }

  // 重新搜索设备
  Future<void> _refreshDevices() async {
    setState(() {
      _devices = [];
      _selectedDevice = null;
    });
    await _startDiscovery();
  }

  // 开始发现设备
  Future<void> _startDiscovery() async {
    setState(() => _isDiscovering = true);

    try {
      await _api.startDiscovery(
        DiscoveryOptions(
          timeout: DiscoveryTimeout(seconds: 15),
          searchTarget: SearchTarget(target: 'upnp:rootdevice'),
        ),
      );

      // 定期获取设备列表
      _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (
        timer,
      ) async {
        try {
          var devices = await _api.getDiscoveredDevices();
          if (mounted) {
            if (devices.isEmpty) {
              // devices = [
              //   DlnaDevice(
              //     udn: DeviceUdn(value: "upnp1"),
              //     friendlyName: '我的投屏工具1',
              //     deviceType: 'MediaRenderer',
              //     manufacturerDetails: ManufacturerDetails(manufacturer: '测试1'),
              //     modelDetails: ModelDetails(modelName: "模式1"),
              //     ipAddress: IpAddress(value: "10.10.10.2"),
              //     port: NetworkPort(value: 9800),
              //   ),
              //   DlnaDevice(
              //     udn: DeviceUdn(value: "upnp2"),
              //     friendlyName: '我的投屏工具2',
              //     deviceType: 'MediaServer',
              //     manufacturerDetails: ManufacturerDetails(manufacturer: '测试2'),
              //     modelDetails: ModelDetails(modelName: "模式2"),
              //     ipAddress: IpAddress(value: "10.10.10.3"),
              //     port: NetworkPort(value: 9800),
              //   ),
              // ];
            }
            if (widget.devicesType != DevicesType.all) {
              String containsStr = widget.devicesType == DevicesType.renderer
                  ? 'MediaRenderer'
                  : 'MediaServer';
              devices = devices
                  .where((device) => device.deviceType.contains(containsStr))
                  .toList();
            }
            setState(() => _devices = devices);
          }

          // 10秒后停止搜索
          if (timer.tick >= 5) {
            timer.cancel();
            await _stopDiscovery();
          }
        } catch (e) {
          if (kDebugMode) {
            print('获取设备列表失败: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('设备发现失败: $e');
      }
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    }
  }

  // 停止发现设备
  Future<void> _stopDiscovery() async {
    _discoveryTimer?.cancel();
    try {
      await _api.stopDiscovery();
    } catch (e) {
      if (kDebugMode) {
        print('停止设备发现失败: $e');
      }
    }
    if (mounted) {
      setState(() => _isDiscovering = false);
    }
  }
}
