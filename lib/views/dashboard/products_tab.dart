import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../core/api_client.dart'; // Add this line
import '../../core/constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isDesktop 
          ? FloatingActionButton(
              onPressed: () => _showProductDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.15),
              const Color(0xFFF4F7F4),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 32),
                _buildFilters(),
                const SizedBox(height: 24),
                Expanded(child: _buildProductTable()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeaderText(),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 50)),
          ),
      ],
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Products', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Manage your inventory and availability', style: TextStyle(color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(child: _buildSearchField()),
                const VerticalDivider(),
                _buildCategoryDropdown(),
              ],
            );
          } else {
            return Column(
              children: [
                _buildSearchField(),
                const Divider(),
                _buildCategoryDropdown(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search products...',
        prefixIcon: Icon(Icons.search_rounded),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        return DropdownButton<String>(
          hint: const Text('All Categories'),
          value: _selectedCategoryId,
          underline: const SizedBox(),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Categories')),
            ...catProvider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        );
      },
    );
  }

  Widget _buildProductTable() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final filteredProducts = provider.products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
          return matchesSearch && matchesCategory;
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Visibility')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredProducts.map((p) => _buildDataRow(p)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Product p) {
    return DataRow(cells: [
      DataCell(Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: p.image != null && p.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: p.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.primary.withOpacity(0.05),
                        child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary.withOpacity(0.05),
                        child: const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      color: AppColors.primary.withOpacity(0.05),
                      child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${p.id.substring(p.id.length - 6).toUpperCase()}',
                  style: TextStyle(color: AppColors.textLight, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      )),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p.categoryName ?? 'General',
          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      )),
      DataCell(Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (p.stock < 10 ? Colors.red : Colors.green).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p.stock.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p.stock < 10 ? Colors.red : Colors.green,
            fontSize: 12,
          ),
        ),
      )),
      DataCell(Switch.adaptive(
        value: p.isVisible,
        onChanged: (val) => context.read<ProductProvider>().toggleVisibility(p.id, val),
        activeColor: AppColors.primary,
      )),
      DataCell(Row(
        children: [
          _buildActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            onTap: () => _showProductDialog(product: p),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            onTap: () => _showDeleteConfirm(p),
          ),
        ],
      )),
    ]);
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(product: product),
    );
  }

  void _showDeleteConfirm(Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(p.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Product? product;
  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient(); // Add this line
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  final TextEditingController _productLinkController = TextEditingController();
  String? _selectedCategory;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _priceController = TextEditingController(text: widget.product?.price.toString());
    _stockController = TextEditingController(text: widget.product?.stock.toString());
    _descController = TextEditingController(text: widget.product?.description);
    _imageController = TextEditingController(text: widget.product?.image);
    _selectedCategory = widget.product?.categoryId;

    // Ensure categories are loaded when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = context.read<CategoryProvider>();
      if (catProvider.categories.isEmpty) {
        catProvider.fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _productLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return AlertDialog(
      title: Text(widget.product == null ? 'New Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Consumer<CategoryProvider>(
                builder: (context, catProvider, _) {
                  final categories = catProvider.categories;
                  
                  if (catProvider.isLoading && categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    );
                  }

                  if (categories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Please create a category first.',
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                                onPressed: () => context.read<CategoryProvider>().fetchCategories(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: categories.any((c) => c.id == _selectedCategory) ? _selectedCategory : null,
                    items: categories.map((c) => DropdownMenuItem(
                      value: c.id, 
                      child: Text(c.name, style: const TextStyle(fontSize: 14))
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    validator: (v) => v == null ? 'Required' : null,
                    hint: const Text('Select a category'),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price (₹)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productLinkController,
                decoration: InputDecoration(
                  labelText: 'Product Link',
                  hintText: 'https://example.com/product',
                  prefixIcon: const Icon(Icons.link_outlined),
                  suffixIcon: _isFetching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.cloud_download_outlined),
                          onPressed: _fetchProductData,
                          tooltip: 'Fetch product data from link',
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/product.jpg',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'name': _nameController.text,
                'category': _selectedCategory,
                'price': double.tryParse(_priceController.text) ?? 0.0,
                'stock': int.tryParse(_stockController.text) ?? 0,
                'description': _descController.text,
                'image': _imageController.text,
                'visibility': (widget.product?.isVisible ?? true) ? 'visible' : 'hidden',
              };

              bool success;
              if (widget.product == null) {
                success = await context.read<ProductProvider>().addProduct(data);
              } else {
                success = await context.read<ProductProvider>().updateProduct(widget.product!.id, data);
              }

              if (success && mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Save Product'),
        ),
      ],
    );
  }

  Future<void> _fetchProductData() async {
    final url = _productLinkController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product link')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    setState(() => _isFetching = true);

    try {
      final client = ApiClient(); // Use a local instance to be safe
      final response = await client.post('/products/admin/extract-url', {
        'productUrl': url, // Updated key from 'url' to 'productUrl'
      });
      
      debugPrint('Extract URL Status: ${response.statusCode}');
      debugPrint('Extract URL Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productData = data['data'] ?? data;
        
        if (mounted) {
          setState(() {
            if (productData['name'] != null) {
              _nameController.text = productData['name'];
            }
            if (productData['description'] != null) {
              _descController.text = productData['description'];
            }
            if (productData['image'] != null) {
              _imageController.text = productData['image'];
            }
            if (productData['price'] != null) {
              _priceController.text = productData['price'].toString();
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product data fetched from server!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server extraction failed: $e. Falling back to local fetch...')),
        );
        // Fallback to local scraping if server fails
        _fetchProductDataLocal(url);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _fetchProductDataLocal(String url) async {
    setState(() => _isFetching = true);
    try {
      // Existing proxy logic as fallback
      final proxyUrl = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}';
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final htmlContent = jsonResponse['contents'];
        final document = parser.parse(htmlContent);
        
        String? productName = _extractMetaContent(document, ['og:title', 'twitter:title', 'product:name', 'name']);
        if (productName == null || productName.isEmpty) productName = document.querySelector('title')?.text.trim();

        String? description = _extractMetaContent(document, ['og:description', 'twitter:description', 'description', 'product:description']);
        String? image = _extractMetaContent(document, ['og:image', 'twitter:image', 'product:image', 'image']);
        String? price = _extractMetaContent(document, ['product:price:amount', 'price', 'og:price:amount']);

        if (mounted) {
          setState(() {
            if (productName != null) _nameController.text = productName;
            if (description != null) _descController.text = description;
            if (image != null) _imageController.text = image;
            if (price != null) _priceController.text = price;
          });
        }
      }
    } catch (e) {
      debugPrint('Local fetch also failed: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  String? _extractMetaContent(dom.Document document, List<String> properties) {
    for (final prop in properties) {
      // Try og:property
      final meta = document.querySelector('meta[property="$prop"]');
      if (meta != null) {
        final content = meta.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
      // Try name=property
      final metaName = document.querySelector('meta[name="$prop"]');
      if (metaName != null) {
        final content = metaName.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
    }
    return null;
  }
}
