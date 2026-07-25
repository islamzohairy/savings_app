import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, this.onUnlocked});
  final VoidCallback? onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isSetup = false;
  String _pin = '';
  String _enteredPin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final existingPin = await _storage.read(key: 'app_lock_pin');
    _isSetup = existingPin != null && existingPin.isNotEmpty;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 16 : 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: isSmall ? 48 : 64),
                      SizedBox(height: isSmall ? 16 : 24),
                      Text(_isSetup ? 'Enter PIN' : 'Set PIN', style: Theme.of(context).textTheme.headlineSmall),
                      SizedBox(height: isSmall ? 16 : 24),
                      if (_error != null) ...[
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        SizedBox(height: isSmall ? 4 : 8),
                      ],
                      _pinDots(),
                      SizedBox(height: isSmall ? 16 : 24),
                      _keypad(isSmall: isSmall),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pinDots() {
    final display = _isSetup ? _enteredPin : _pin;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < display.length ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
        ),
      )),
    );
  }

  Widget _keypad({required bool isSmall}) {
    final keyWidth = isSmall ? 56.0 : 64.0;
    final keyHeight = isSmall ? 48.0 : 56.0;
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return SizedBox(width: keyWidth, height: keyHeight);
              return Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: keyWidth,
                  height: keyHeight,
                  child: OutlinedButton(
                    onPressed: () => _onKey(key),
                    child: Text(key, style: TextStyle(fontSize: isSmall ? 18 : 20)),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _onKey(String key) {
    setState(() => _error = null);
    if (key == '⌫') {
      setState(() {
        if (_isSetup) {
          _enteredPin = _enteredPin.isNotEmpty ? _enteredPin.substring(0, _enteredPin.length - 1) : '';
        } else {
          _pin = _pin.isNotEmpty ? _pin.substring(0, _pin.length - 1) : '';
        }
      });
      return;
    }

    final current = _isSetup ? _enteredPin : _pin;
    if (current.length >= 4) return;

    final updated = current + key;

    if (_isSetup) {
      _enteredPin = updated;
    } else {
      _pin = updated;
    }
    setState(() {});

    if (updated.length == 4) {
      _handleComplete(updated);
    }
  }

  Future<void> _handleComplete(String pin) async {
    if (_isSetup) {
      final stored = await _storage.read(key: 'app_lock_pin');
      if (pin == stored) {
        widget.onUnlocked?.call();
      } else {
        setState(() {
          _error = 'Wrong PIN';
          _enteredPin = '';
        });
      }
    } else {
      // Save new PIN
      await _storage.write(key: 'app_lock_pin', value: pin);
      setState(() {
        _isSetup = true;
        _enteredPin = '';
      });
      widget.onUnlocked?.call();
    }
  }
}
