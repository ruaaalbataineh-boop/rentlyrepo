import 'package:flutter/material.dart';
import 'payment_success_page.dart';
import 'payment_failed_page.dart';

class CreditCardPaymentPage extends StatefulWidget {
  final double amount;
  
  const CreditCardPaymentPage({super.key, required this.amount});

  @override
  State<CreditCardPaymentPage> createState() => _CreditCardPaymentPageState();
}

class _CreditCardPaymentPageState extends State<CreditCardPaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  bool isProcessing = false;
  String? cardType;
  bool _showErrors = false;

  
  String? _cardNumberError;
  String? _cardHolderError;
  String? _expiryDateError;
  String? _cvvError;

  @override
  void initState() {
    super.initState();
    cardNumberController.addListener(_detectCardType);
    
    cardNumberController.addListener(() => _updateCardNumberError());
    cardHolderController.addListener(() => _updateCardHolderError());
    expiryController.addListener(() => _updateExpiryDateError());
    cvvController.addListener(() => _updateCVVError());
  }

  @override
  void dispose() {
    cardNumberController.removeListener(_detectCardType);
    cardNumberController.removeListener(() => _updateCardNumberError());
    cardHolderController.removeListener(() => _updateCardHolderError());
    expiryController.removeListener(() => _updateExpiryDateError());
    cvvController.removeListener(() => _updateCVVError());
    super.dispose();
  }

  void _detectCardType() {
    final cardNumber = cardNumberController.text.replaceAll(' ', '');
    
    if (cardNumber.isEmpty) {
      setState(() {
        cardType = null;
      });
      return;
    }

    if (cardNumber.startsWith('4')) {
      setState(() {
        cardType = 'Visa';
      });
    } else {
      setState(() {
        cardType = null;
      });
    }
  }

  void _updateCardNumberError() {
    setState(() {
      _cardNumberError = _validateCardNumberInput(cardNumberController.text);
    });
  }

  void _updateCardHolderError() {
    setState(() {
      _cardHolderError = _validateCardHolder(cardHolderController.text);
    });
  }

  void _updateExpiryDateError() {
    setState(() {
      _expiryDateError = _validateExpiryDateInput(expiryController.text);
    });
  }

  void _updateCVVError() {
    setState(() {
      _cvvError = _validateCVV(cvvController.text);
    });
  }

  bool _validateCardNumber(String cardNumber) {
    final cleanedCardNumber = cardNumber.replaceAll(' ', '');
    
    if (cleanedCardNumber.length != 16) return false;
    if (!cleanedCardNumber.startsWith('4')) return false;
    
    return _luhnAlgorithm(cleanedCardNumber);
  }

  bool _luhnAlgorithm(String number) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  bool _validateExpiryDate(String expiry) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiry)) {
      return false;
    }
    
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    
    return true;
  }

  String? _validateCardHolder(String? name) {
    if (name == null || name.isEmpty) {
      return 'Please enter card holder name';
    }
    
    if (name.length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    if (name.length > 50) {
      return 'Name is too long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name must contain only letters and spaces';
    }
    
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Please enter full name (first and last name)';
    }
    
    for (final word in words) {
      if (word.length < 2) {
        return 'Each name part must be at least 2 characters';
      }
    }
    
    return null;
  }

  String? _validateCardNumberInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    
    final cleanedValue = value.replaceAll(' ', '');
    
    if (cleanedValue.length != 16) {
      return 'Card number must be 16 digits';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
      return 'Card number must contain only digits';
    }
    
    if (!cleanedValue.startsWith('4')) {
      return 'Only Visa cards are accepted (must start with 4)';
    }
    
    if (!_validateCardNumber(cleanedValue)) {
      return 'Invalid Visa card number';
    }
    
    return null;
  }

  String? _validateExpiryDateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
      return 'Format: MM/YY (e.g., 12/25)';
    }
    
    if (!_validateExpiryDate(value)) {
      return 'Card has expired or invalid date';
    }
    
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    
    if (!RegExp(r'^[0-9]{3}$').hasMatch(value)) {
      return 'CVV must be 3 digits';
    }
    
    return null;
  }

  void _validateAndShowErrors() {
    setState(() {
      _showErrors = true;

      _cardNumberError = _validateCardNumberInput(cardNumberController.text);
      _cardHolderError = _validateCardHolder(cardHolderController.text);
      _expiryDateError = _validateExpiryDateInput(expiryController.text);
      _cvvError = _validateCVV(cvvController.text);
    });
    
    final hasErrors = _cardNumberError != null || 
                     _cardHolderError != null || 
                     _expiryDateError != null || 
                     _cvvError != null;
    
    if (hasErrors) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please fill in all required fields correctly',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A005D).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Visa Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'VISA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  if (cardType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Valid Visa Card',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: cardNumberController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: '4XXX XXXX XXXX XXXX',
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          suffixIcon: cardType != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        onChanged: (value) {
                          final cleanedValue = value.replaceAll(' ', '');
                          var formattedValue = '';
                          
                          for (int i = 0; i < cleanedValue.length; i++) {
                            if (i > 0 && i % 4 == 0) {
                              formattedValue += ' ';
                            }
                            formattedValue += cleanedValue[i];
                          }
                          
                          if (formattedValue != value) {
                            cardNumberController.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(offset: formattedValue.length),
                            );
                          }
                        },
                      ),
  
                      if (_showErrors && _cardNumberError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.yellow[300],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _cardNumberError!,
                                  style: TextStyle(
                                    color: Colors.yellow[300],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: cardHolderController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'FULL NAME',
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                                
                                if (_showErrors && _cardHolderError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.yellow[300],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _cardHolderError!,
                                            style: TextStyle(
                                              color: Colors.yellow[300],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EXPIRY DATE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: expiryController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'MM/YY',
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  onChanged: (value) {
                                    final cleanedValue = value.replaceAll('/', '');
                                    
                                    if (cleanedValue.length == 2 && value.length == 2) {
                                      expiryController.text = '$value/';
                                      expiryController.selection = TextSelection.collapsed(offset: 3);
                                    } else if (cleanedValue.length > 4) {
                                      expiryController.text = '${cleanedValue.substring(0, 2)}/${cleanedValue.substring(2, 4)}';
                                      expiryController.selection = TextSelection.collapsed(offset: 5);
                                    }
                                  },
                                ),
                                
                                if (_showErrors && _expiryDateError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.yellow[300],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _expiryDateError!,
                                            style: TextStyle(
                                              color: Colors.yellow[300],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: 15),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Fee:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock, color: Color(0xFF8A005D)),
                        SizedBox(width: 10),
                        Text(
                          'Security Code (CVV)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F0F46),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cvvController,
                                obscureText: true,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: '123',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.security, color: Color(0xFF8A005D)),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.help_outline, color: Colors.white, size: 24),
                                  SizedBox(height: 8),
                                  Text(
                                    '3 digits\nback side',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (_showErrors && _cvvError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[800],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _cvvError!,
                                    style: TextStyle(
                                      color: Colors.red[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Visa cards have 3-digit CVV on the back',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFF8A005D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Visa Card Requirements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F0F46),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRequirement('Card number must start with 4'),
                  _buildRequirement('Card number must be 16 digits'),
                  _buildRequirement('Card holder name must be full name'),
                  _buildRequirement('Expiry date must be in MM/YY format'),
                  _buildRequirement('CVV must be 3 digits on the back'),
                  _buildRequirement('Only Visa cards are accepted'),
                ],
              ),
            ),

            const SizedBox(height: 25),

           
            if (_showErrors && (_cardNumberError != null || _cardHolderError != null || _expiryDateError != null || _cvvError != null))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[800], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please fill in all required fields correctly',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A005D).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isProcessing ? null : _processPayment,
                    child: Center(
                      child: isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Confirm Payment',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is 100% secure. We use 256-bit SSL encryption to protect your financial information.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      )
    );
  }

  void _processPayment() async {

    _validateAndShowErrors();


    final hasErrors = _cardNumberError != null || 
                     _cardHolderError != null || 
                     _expiryDateError != null || 
                     _cvvError != null;
    
    if (hasErrors) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isProcessing = false;
    });

    final isSuccess = DateTime.now().millisecond % 10 < 8;
    
    if (isSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessPage(amount: widget.amount),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentFailedPage(),
        ),
      );
    }
  }
}
