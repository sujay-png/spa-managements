import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/theme/responsive.dart';
import 'package:provider/provider.dart';

class CustomerTabel extends StatefulWidget {
  final Function(CustomerModel) onEdit;
  const CustomerTabel({super.key, required this.onEdit});

  @override
  State<CustomerTabel> createState() => _CustomerTabelState();
}

class _CustomerTabelState extends State<CustomerTabel> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();

      if (auth.businessRef != null) {
        context.read<ServiceController>().loadServices(auth.businessRef!);
      } else {
        debugPrint("Business Ref is null");
      }
    });
  }

  int _currentPage = 0;
  final int _rowsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerController>();
    final BookingController = context.watch<CustomerController>();

    final customers = customer.customers;

    final totalPages = customers.isEmpty
        ? 1
        : (customers.length / _rowsPerPage).ceil();

    final startIndex = _currentPage * _rowsPerPage;

    final endIndex = (startIndex + _rowsPerPage) > customers.length
        ? customers.length
        : startIndex + _rowsPerPage;

    final paginatedCustomers = customers.isEmpty
        ? <CustomerModel>[]
        : customers.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Table Header Row
          if (!context.isMobile)
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'CUST ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CONTACT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'VISITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'TOTAL SPENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'LAST VISIT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(width: 30),
              ],
            ),
          ),

          customer.loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : paginatedCustomers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No customers found')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paginatedCustomers.length,
                  itemBuilder: (context, index) {
                    final item = paginatedCustomers[index];

                    return IgnorePointer(
                      ignoring: item.isblacklisted,
                      child: Opacity(
                        opacity: item.isblacklisted ? 0.4 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: item.isblacklisted
                                ? Colors.grey.shade200
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: index == paginatedCustomers.length - 1
                                    ? 0
                                    : 1,
                              ),
                            ),
                          ),
                          child: context.isMobile
                              ? _mobileCustomerRow(context, item)
                              : Row(
                            children: [
                              //====================== Cust ID ======================
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatCustomerId(item.id),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              //====================== Name ======================
                              Expanded(
                                flex: 3,
                                child: Row(
                                  spacing: 15,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: AppColors.border,
                                      child: Text(
                                        _initials(item.name),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              //====================== Email / Phone ======================
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.email,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      item.phoneno,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //====================== Visits ======================
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.totalVisits}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //====================== Total Spent ======================
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.spentThisMonth.toStringAsFixed(2),

                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //====================== Last Visit ======================
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.lastVisit != null
                                      ? '${item.lastVisit!.day}/${item.lastVisit!.month}/${item.lastVisit!.year}'
                                      : '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              //====================== Actions ======================
                              SizedBox(
                                width: 30,
                                child: PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      widget.onEdit(item);
                                    } else if (value == 'delete') {
                                      _deletecustomer(item);
                                    } else if (value == 'block') {
                                      context
                                          .read<CustomerController>()
                                          .toggleBlacklistCustomer(
                                            item.id!,
                                            item.isblacklisted,
                                          );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.isblacklisted
                                                ? Icons.check_circle_outline
                                                : Icons.block,
                                            size: 16,
                                            color: item.isblacklisted
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.isblacklisted
                                                ? 'Unblock Customer'
                                                : 'Block Customer',
                                            style: TextStyle(
                                              color: item.isblacklisted
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

          //================================== Pagination ==================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              spacing: 12,
              children: [
                Text(
                  customers.isEmpty
                      ? 'Showing 0 of 0 entries'
                      : 'Showing ${startIndex + 1}-$endIndex of ${customers.length} entries',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Page ${_currentPage + 1} of $totalPages',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileCustomerRow(BuildContext context, CustomerModel item) {
    final lastVisit = item.lastVisit == null
        ? 'No visits yet'
        : '${item.lastVisit!.day}/${item.lastVisit!.month}/${item.lastVisit!.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.border,
                child: Text(
                  _initials(item.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCustomerId(item.id),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit(item);
                  } else if (value == 'delete') {
                    _deletecustomer(item);
                  } else if (item.id != null) {
                    context.read<CustomerController>().toggleBlacklistCustomer(
                          item.id!,
                          item.isblacklisted,
                        );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text(item.isblacklisted ? 'Unblock Customer' : 'Block Customer'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            item.phoneno,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _mobileDetail('Visits', '${item.totalVisits}'),
              _mobileDetail('Spent', '\u{20B9}${item.spentThisMonth.toStringAsFixed(2)}'),
              _mobileDetail('Last visit', lastVisit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---- Edit / Delete actions ----

  Future<void> _deletecustomer(CustomerModel customer) async {
    if (customer.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete customer"),
        content: const Text("Are you sure you want to delete this booking?"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await context.read<CustomerController>().deletecustomer(customer.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer deleted successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  // void _deleteCustomer(CustomerModel item) {
  //   if (item.id == null) return;
  //   context.read<CustomerController>().deleteCustomer(item.id!);
  // }

  String _formatCustomerId(int? id) {
    if (id == null) return 'CUS---';
    return 'CUS${id.toString().padLeft(3, '0')}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
