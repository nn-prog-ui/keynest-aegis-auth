import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shared_credential_bridge.dart';

class ServiceAccountAddScreen extends StatefulWidget {
  const ServiceAccountAddScreen({
    super.key,
    this.initialServiceName = '',
    this.initialDomains = '',
    this.initialLoginUrl = '',
    this.initialCurrency = 'JPY',
    this.initialBillingCycle = 'monthly',
  });

  final String initialServiceName;
  final String initialDomains;
  final String initialLoginUrl;
  final String initialCurrency;
  final String initialBillingCycle;

  @override
  State<ServiceAccountAddScreen> createState() =>
      _ServiceAccountAddScreenState();
}

class _ServiceAccountAddScreenState extends State<ServiceAccountAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _credentialBridge = const SharedCredentialBridge();

  late final TextEditingController _serviceNameController;
  late final TextEditingController _domainsController;
  late final TextEditingController _loginUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _monthlyPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _billingCycleController;
  late final TextEditingController _renewalDateController;
  late final TextEditingController _paymentMethodController;
  late final TextEditingController _cancelUrlController;

  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serviceNameController =
        TextEditingController(text: widget.initialServiceName);
    _domainsController = TextEditingController(text: widget.initialDomains);
    _loginUrlController = TextEditingController(text: widget.initialLoginUrl);
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _monthlyPriceController = TextEditingController();
    _currencyController = TextEditingController(text: widget.initialCurrency);
    _billingCycleController =
        TextEditingController(text: widget.initialBillingCycle);
    _renewalDateController = TextEditingController();
    _paymentMethodController = TextEditingController();
    _cancelUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _domainsController.dispose();
    _loginUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _monthlyPriceController.dispose();
    _currencyController.dispose();
    _billingCycleController.dispose();
    _renewalDateController.dispose();
    _paymentMethodController.dispose();
    _cancelUrlController.dispose();
    super.dispose();
  }

  List<String> get _domains {
    return _domainsController.text
        .split(RegExp(r'[\n,]'))
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _saveServiceAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final renewalDateText = _renewalDateController.text.trim();
    DateTime? renewalDate;
    if (renewalDateText.isNotEmpty) {
      renewalDate = DateTime.tryParse(renewalDateText);
      if (renewalDate == null) {
        _showLocalSnack('更新日は YYYY-MM-DD 形式で入力してください');
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _credentialBridge.saveCredential(
        SharedCredentialSaveRequest(
          serviceName: _serviceNameController.text.trim(),
          domains: _domains,
          loginUrl: _loginUrlController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          monthlyPrice: _monthlyPriceController.text.trim(),
          currency: _currencyController.text.trim().toUpperCase(),
          billingCycle: _billingCycleController.text.trim(),
          renewalDate: renewalDate,
          paymentMethod: _paymentMethodController.text.trim(),
          cancelUrl: _cancelUrlController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_serviceNameController.text.trim());
    } on PlatformException catch (error) {
      _showLocalSnack('保存に失敗しました: ${error.message ?? error.code}');
    } catch (error) {
      _showLocalSnack('保存に失敗しました: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showLocalSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$labelを入力してください';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サービス追加'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ログイン情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _serviceNameController,
                        decoration: const InputDecoration(labelText: 'サービス名'),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'サービス名'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _domainsController,
                        decoration: const InputDecoration(
                          labelText: 'ドメイン',
                          hintText: 'amazon.co.jp, www.amazon.co.jp',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'ドメイン'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _loginUrlController,
                        decoration: const InputDecoration(labelText: 'ログインURL'),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _usernameController,
                        decoration:
                            const InputDecoration(labelText: 'メールアドレス / ID'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'メールアドレス / ID'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip: _obscurePassword ? '表示' : '非表示',
                          ),
                        ),
                        obscureText: _obscurePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'パスワード'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'サブスク情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _monthlyPriceController,
                        decoration: const InputDecoration(labelText: '月額料金'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(labelText: '通貨'),
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _billingCycleController,
                        decoration: const InputDecoration(
                          labelText: '請求周期',
                          hintText: 'monthly / yearly',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _renewalDateController,
                        decoration: const InputDecoration(
                          labelText: '更新日',
                          hintText: 'YYYY-MM-DD',
                        ),
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _paymentMethodController,
                        decoration: const InputDecoration(labelText: '支払い方法'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cancelUrlController,
                        decoration: const InputDecoration(labelText: '解約URL'),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveServiceAccount,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline_rounded),
                label: Text(_isSaving ? '保存中' : '保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
