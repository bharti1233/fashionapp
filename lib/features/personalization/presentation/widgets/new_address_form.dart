import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/validators/validation.dart';

class NewAddressForm extends StatefulWidget {
  const NewAddressForm({super.key});
  @override
  State<NewAddressForm> createState() => _NewAddressFormState();
}

class _NewAddressFormState extends State<NewAddressForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  static const List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.user),
              labelText: "Full Name",
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Full name is required' : null,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.mobile),
              labelText: "Phone Number",
              hintText: "+91 98765 43210",
            ),
            validator: (value) => TValidator.validatePhoneNumber(value),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.building_31),
              labelText: "Address Line 1",
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.building_31),
              labelText: "Address Line 2 (Optional)",
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.building),
                    labelText: "City",
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'City is required' : null,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwInputFields),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _stateController.text.isNotEmpty ? _stateController.text : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.activity),
                    labelText: "State",
                  ),
                  items: _indianStates.map((state) => DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _stateController.text = value ?? '';
                    });
                  },
                  validator: (value) => value?.isEmpty ?? true ? 'State is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.code),
              labelText: "PIN Code",
              hintText: "6-digit PIN",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PIN code is required';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                return 'Enter a valid 6-digit PIN code';
              }
              return null;
            },
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            initialValue: 'India',
            readOnly: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.global),
              labelText: "Country",
            ),
          ),
          const SizedBox(height: TSizes.defaultSpace),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Save address logic here
                }
              },
              child: const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
