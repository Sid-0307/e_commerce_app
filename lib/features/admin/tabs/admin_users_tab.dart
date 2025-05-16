import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({Key? key}) : super(key: key);

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();

    _tabController.addListener(() {
      setState(() {
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _firestoreService.getAllUsers();
      final filteredUsers = users.where((user) =>
        user.userType != 'Admin'
      ).toList();
      setState(() {
        _users = filteredUsers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load users: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      // Filter based on tab selection and search query
      _filteredUsers = _users.where((user) {
        // Apply search filter
        final nameMatches = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final emailMatches = user.email.toLowerCase().contains(_searchQuery.toLowerCase());

        // Apply user type filter based on tab
        bool typeMatches = true;
        if (_tabController.index == 1) {
          typeMatches = user.userType == 'Buyer';
        } else if (_tabController.index == 2) {
          typeMatches = user.userType == 'Seller';
        }

        return (nameMatches || emailMatches) && typeMatches;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      await _firestoreService.deleteUser(user.uid);
      setState(() {
        _users.removeWhere((u) => u.uid == user.uid);
        _applyFilters();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete user: $e');
    }
  }

  Future<void> _showDeleteConfirmation(UserModel user) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${user.name}?'),
                const SizedBox(height: 10),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(user);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUserDetailsDialog(UserModel user) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('Email', user.email),
                _infoRow('User Type', user.userType),
                _infoRow('Phone', user.completePhoneNumber),
                _infoRow('Country', user.countryISOCode),
                if (user.address != null && user.address!.isNotEmpty)
                  _infoRow('Address', user.address!),
                if (user.aboutUs != null && user.aboutUs!.isNotEmpty)
                  _infoRow('About', user.aboutUs!),
                if (user.hsCodePreferences.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('HS Code Preferences:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    children: user.hsCodePreferences
                        .map((code) => Chip(
                      label: Text(code),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToEditUser(user);
              },
              child: const Text('Edit User'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _navigateToEditUser(UserModel user) {
    // Navigate to edit user screen (to be implemented)
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EditUserScreen(user: user),
    //     fullscreenDialog: true,
    //   ),
    // ).then((_) => _loadUsers());

    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit user functionality to be implemented'),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No users found'
                  : 'No users match your search criteria',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.userType == 'Buyer'
                    ? AppColors.primary.withOpacity(0.7)
                    : Colors.amber[700],
                child: Icon(
                  user.userType == 'Buyer' ? Icons.person : Icons.store,
                  color: Colors.white,
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.userType == 'Buyer'
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.amber[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.userType,
                          style: TextStyle(
                            fontSize: 12,
                            color: user.userType == 'Buyer'
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.countryISOCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.countryISOCode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'details':
                      _showUserDetailsDialog(user);
                      break;
                    case 'edit':
                      _navigateToEditUser(user);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(user);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit User'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showUserDetailsDialog(user),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8,16,8,0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'All Users'),
                    Tab(text: 'Buyers'),
                    Tab(text: 'Sellers'),
                  ],
                  onTap: (_) {
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (_) => _buildUserList()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadUsers,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: AppColors.tertiary,
      ),
    );
  }
}