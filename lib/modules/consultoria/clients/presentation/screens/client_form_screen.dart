import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/clients_providers.dart';
import '../../domain/client.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Novo Cliente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: _saveClient,
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Photo Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _photoPath != null
                              ? FileImage(File(_photoPath!))
                              : null,
                          child: _photoPath == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Adicionar Foto',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nome Completo',
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'Nome obrigatório',
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Telefone',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v?.isNotEmpty == true
                            ? null
                            : 'Telefone obrigatório',
                      ),
                      const SizedBox(height: 16),

                      // City & State
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'Cidade',
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Obg',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _stateController,
                              label: 'UF',
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Obg',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  void _saveClient() {
    if (_formKey.currentState?.validate() == true) {
      final newClient = Client(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        state: _stateController.text,
        photoPath: _photoPath,
        createdAt: DateTime.now(),
      );

      ref.read(clientsControllerProvider).saveClient(newClient);
      context.pop();
    }
  }
}
