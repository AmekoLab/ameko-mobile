import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_state.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/screens/pin_setup_screen.dart';
import 'package:ameko_app/features/payment/presentation/widgets/payment_method_selector.dart';

class CheckoutScreen extends StatefulWidget {
  final List<String> selectedOrderItemIds;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.selectedOrderItemIds,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.vnpay;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWallet());
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onPlaceOrder(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == PaymentMethod.vnpay) {
      context.read<CheckoutBloc>().add(CheckoutWithVnpay(
            selectedOrderItemIds: widget.selectedOrderItemIds,
            shippingAddress: _addressCtrl.text.trim(),
            receiverName: _nameCtrl.text.trim(),
            receiverPhone: _phoneCtrl.text.trim(),
            shippingNote: _noteCtrl.text.trim(),
          ));
    } else {
      _showPinBottomSheet(context);
    }
  }

  Future<void> _showPinBottomSheet(BuildContext context) async {
    final walletBloc = context.read<WalletBloc>();
    // Check PIN status first
    walletBloc.add(CheckPinStatus());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: walletBloc,
        child: _WalletPinSheet(
          onPinSubmitted: (pin) {
            Navigator.of(context).pop();
            context.read<CheckoutBloc>().add(CheckoutWithWallet(
                  selectedOrderItemIds: widget.selectedOrderItemIds,
                  shippingAddress: _addressCtrl.text.trim(),
                  receiverName: _nameCtrl.text.trim(),
                  receiverPhone: _phoneCtrl.text.trim(),
                  walletPin: pin,
                  shippingNote: _noteCtrl.text.trim(),
                ));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutVnpayReady) {
          context.push('/payment/vnpay-webview', extra: {
            'paymentUrl': state.paymentUrl,
            'checkoutBloc': context.read<CheckoutBloc>(),
          });
        }
 else if (state is CheckoutSuccess) {
          context.pushReplacement('/payment/result', extra: {
            'success': true,
            'paymentMethod': state.result.paymentMethod,
            'message': state.result.message ?? 'Đặt hàng thành công!',
          });
        } else if (state is CheckoutFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Đặt hàng',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Shipping Info ───────────────────────────────
                _buildSection(
                  title: 'Thông tin giao hàng',
                  icon: Icons.local_shipping_outlined,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Tên người nhận',
                        hint: 'Nguyễn Văn A',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _phoneCtrl,
                        label: 'Số điện thoại',
                        hint: '0901234567',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (v.trim().length < 9) return 'Số điện thoại không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _addressCtrl,
                        label: 'Địa chỉ giao hàng',
                        hint: 'Số 1, Võ Văn Ngân, Thủ Đức, TP.HCM',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _noteCtrl,
                        label: 'Ghi chú (Không bắt buộc)',
                        hint: 'Ghi chú cho người bán hoặc người giao hàng',
                        icon: Icons.note_alt_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Payment Method ──────────────────────────────
                _buildSection(
                  title: 'Phương thức thanh toán',
                  icon: Icons.payment_outlined,
                  child: BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, walletState) {
                      double? balance;
                      if (walletState is WalletLoaded) {
                        balance = walletState.wallet.balance;
                      }
                      return PaymentMethodSelector(
                        selected: _paymentMethod,
                        walletBalance: balance,
                        onChanged: (m) => setState(() => _paymentMethod = m),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Order Summary ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng thanh toán',
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        '${formatter.format(widget.totalAmount.toInt())}đ',
                        style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, formatter),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, NumberFormat formatter) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final isLoading = state is CheckoutLoading;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _onPlaceOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _paymentMethod == PaymentMethod.vnpay
                          ? 'Thanh toán với VNPAY'
                          : 'Thanh toán với Ví (${formatter.format(widget.totalAmount.toInt())}đ)',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Internal PIN Bottom Sheet ────────────────────────────────────────────────

class _WalletPinSheet extends StatefulWidget {
  final ValueChanged<String> onPinSubmitted;
  const _WalletPinSheet({required this.onPinSubmitted});

  @override
  State<_WalletPinSheet> createState() => _WalletPinSheetState();
}

class _WalletPinSheetState extends State<_WalletPinSheet> {
  String _pin = '';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is PinStatusChecked && !state.hasPin) {
          // Navigate to PIN setup
          Navigator.of(context).pop();
          context.push('/wallet/pin-setup');
        }
      },
      builder: (context, state) {
        if (state is WalletLoading) {
          return Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        return _buildPinSheet();
      },
    );
  }

  Widget _buildPinSheet() {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text('Nhập mã PIN ví',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Nhập mã PIN 6 số để xác nhận thanh toán',
                style: AppTextStyles.bodySecondary
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            _PinBoxes(
              onCompleted: (pin) {
                setState(() => _pin = pin);
                widget.onPinSubmitted(pin);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PinBoxes extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  const _PinBoxes({required this.onCompleted});

  @override
  State<_PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<_PinBoxes> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _pin = List.filled(6, '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(int i, String val) {
    if (val.isNotEmpty) {
      _pin[i] = val[0];
      if (i < 5) _focusNodes[i + 1].requestFocus();
      else {
        _focusNodes[i].unfocus();
        widget.onCompleted(_pin.join());
      }
    } else {
      _pin[i] = '';
      if (i > 0) _focusNodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = _pin[i].isNotEmpty;
        return Container(
          width: 44,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(
              color: _focusNodes[i].hasFocus ? AppColors.primary : AppColors.border,
              width: _focusNodes[i].hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  onChanged: (v) => _onChanged(i, v),
                  onTap: () { _controllers[i].clear(); _pin[i] = ''; setState(() {}); },
                ),
              ),
              if (filled)
                Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        );
      }),
    );
  }
}
