import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),
          Expanded(
            child: Column(
              children: [
                const AdminHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildTabSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library Management',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage books, track borrowing and monitor inventory',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _addNewBook,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Add Book',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('library_books').snapshots(),
      builder: (context, bookSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('library_transactions').where('status', isEqualTo: 'borrowed').snapshots(),
          builder: (context, transactionSnapshot) {
            final totalBooks = bookSnapshot.data?.docs.length ?? 0;
            final borrowedCount = transactionSnapshot.data?.docs.length ?? 0;
            
            int overdueCount = 0;
            int availableCount = 0;
            
            if (bookSnapshot.hasData) {
              for (var doc in bookSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                availableCount += (data['copiesAvailable'] ?? 0) as int;
              }
            }
            
            if (transactionSnapshot.hasData) {
              final now = DateTime.now();
              for (var doc in transactionSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                if (dueDate != null && dueDate.isBefore(now)) {
                  overdueCount++;
                }
              }
            }
            
            return Row(
              children: [
                Expanded(child: _buildStatCard('Total Books', totalBooks.toString(), Icons.library_books, const Color(0xFF2563EB), '+12%')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Available', availableCount.toString(), Icons.check_circle, const Color(0xFF10B981), '+8%')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Borrowed', borrowedCount.toString(), Icons.book, const Color(0xFFF59E0B), '+5%')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Overdue', overdueCount.toString(), Icons.warning, const Color(0xFFEF4444), overdueCount > 0 ? '+$overdueCount' : '0')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search books by title, author, ISBN or category...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A1A)),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'All Books'),
              Tab(text: 'Borrowed'),
              Tab(text: 'Overdue'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBooksTab(),
              _buildBorrowedTab(),
              _buildOverdueTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBooksTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('library_books').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            Icons.library_books_outlined,
            'No Books Available',
            'Start building your library by adding books',
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            children: [
              _buildTableHeader(['Book Details', 'Category', 'Copies', 'Status', 'Action']),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var book = doc.data() as Map<String, dynamic>;
                    final bookId = doc.id;
                    final isAvailable = (book['copiesAvailable'] ?? 0) > 0;
                    
                    return _buildBookRow(bookId, book, isAvailable);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              headers[0],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              headers[1],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              headers[2],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              headers[3],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              headers[4],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookRow(String bookId, Map<String, dynamic> book, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book['author'] ?? 'Unknown Author',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                book['category'] ?? 'General',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2563EB),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${book['copiesAvailable']}/${book['totalCopies']}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Out',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isAvailable ? () => _borrowBook(bookId, book) : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  'Borrow',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('library_transactions').where('status', isEqualTo: 'borrowed').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            Icons.book_outlined,
            'No Borrowed Books',
            'All books are currently available in the library',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var transaction = doc.data() as Map<String, dynamic>;
            final transactionId = doc.id;
            final dueDate = (transaction['dueDate'] as Timestamp?)?.toDate();
            final now = DateTime.now();
            final isOverdue = dueDate != null && dueDate.isBefore(now);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverdue
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOverdue ? Icons.warning_rounded : Icons.book_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['bookTitle'] ?? 'Unknown Book',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                transaction['borrowerName'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.badge_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                transaction['borrowerRegNo'] ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red.shade50 : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: isOverdue ? Colors.red : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Due: ${dueDate != null ? "${dueDate.day}/${dueDate.month}/${dueDate.year}" : "N/A"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue ? Colors.red : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _returnBook(transactionId, transaction['bookId']),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text('Return', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverdueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('library_transactions').where('status', isEqualTo: 'borrowed').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            Icons.check_circle_outline,
            'No Overdue Books',
            'All borrowed books are within their due date',
          );
        }
        
        final now = DateTime.now();
        final overdueDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
          return dueDate != null && dueDate.isBefore(now);
        }).toList();
        
        if (overdueDocs.isEmpty) {
          return _buildEmptyState(
            Icons.check_circle_outline,
            'No Overdue Books',
            'All borrowed books are within their due date',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: overdueDocs.length,
          itemBuilder: (context, index) {
            var doc = overdueDocs[index];
            var transaction = doc.data() as Map<String, dynamic>;
            final transactionId = doc.id;
            final dueDate = (transaction['dueDate'] as Timestamp?)?.toDate();
            final daysOverdue = dueDate != null ? now.difference(dueDate).inDays : 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.warning_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  transaction['bookTitle'] ?? 'Unknown Book',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$daysOverdue days overdue',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                transaction['borrowerName'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.badge_outlined, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                transaction['borrowerRegNo'] ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.red),
                                const SizedBox(width: 6),
                                Text(
                                  'Was due: ${dueDate != null ? "${dueDate.day}/${dueDate.month}/${dueDate.year}" : "N/A"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _returnBook(transactionId, transaction['bookId']),
                      icon: const Icon(Icons.assignment_return_outlined, size: 18),
                      label: Text('Return Now', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addNewBook() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();
    final categoryController = TextEditingController();
    final publisherController = TextEditingController();
    final yearController = TextEditingController();
    final copiesController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C51E1), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Book',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the book details below',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildModernTextField(
                          controller: titleController,
                          label: 'Book Title',
                          icon: Icons.book_rounded,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: authorController,
                          label: 'Author',
                          icon: Icons.person_outline,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: isbnController,
                                label: 'ISBN',
                                icon: Icons.numbers,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernTextField(
                                controller: yearController,
                                label: 'Year',
                                icon: Icons.calendar_today,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: categoryController,
                          label: 'Category',
                          icon: Icons.category_outlined,
                          hint: 'e.g., Computer Science, Business',
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: publisherController,
                          label: 'Publisher',
                          icon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: copiesController,
                          label: 'Number of Copies',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                          required: true,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (int.tryParse(value!) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: descriptionController,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          await _saveNewBook(
                            titleController.text,
                            authorController.text,
                            isbnController.text,
                            categoryController.text,
                            publisherController.text,
                            yearController.text,
                            copiesController.text,
                            descriptionController.text,
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text('Add Book', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C51E1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
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
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFF5C51E1), size: 22),
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5C51E1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator ?? (required ? (value) => value?.isEmpty ?? true ? 'Required' : null : null),
    );
  }

  Future<void> _saveNewBook(
    String title,
    String author,
    String isbn,
    String category,
    String publisher,
    String year,
    String copies,
    String description,
  ) async {
    try {
      final totalCopies = int.parse(copies);
      final publicationYear = year.isNotEmpty ? int.tryParse(year) : null;
      
      await FirebaseFirestore.instance.collection('library_books').add({
        'title': title,
        'author': author,
        'isbn': isbn.isNotEmpty ? isbn : 'N/A',
        'category': category,
        'publisher': publisher.isNotEmpty ? publisher : 'N/A',
        'year': publicationYear ?? 0,
        'totalCopies': totalCopies,
        'copiesAvailable': totalCopies,
        'isAvailable': true,
        'description': description.isNotEmpty ? description : 'No description',
        'addedDate': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Book "$title" added successfully!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error adding book: $e', style: GoogleFonts.inter())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _borrowBook(String bookId, Map<String, dynamic> book) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final regNoController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Borrow Book',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book['title'] ?? 'Unknown Book',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _buildModernTextField(
                        controller: nameController,
                        label: 'Student Name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      const SizedBox(height: 20),
                      _buildModernTextField(
                        controller: regNoController,
                        label: 'Registration Number',
                        icon: Icons.badge_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Book will be due in 14 days',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text('Confirm Borrow', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
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
    
    if (result == true) {
      try {
        final now = DateTime.now();
        final dueDate = now.add(const Duration(days: 14));
        
        await FirebaseFirestore.instance.collection('library_transactions').add({
          'bookId': bookId,
          'bookTitle': book['title'],
          'bookAuthor': book['author'],
          'bookIsbn': book['isbn'],
          'borrowerName': nameController.text,
          'borrowerRegNo': regNoController.text,
          'borrowDate': Timestamp.fromDate(now),
          'dueDate': Timestamp.fromDate(dueDate),
          'status': 'borrowed',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        final currentAvailable = book['copiesAvailable'] ?? 0;
        await FirebaseFirestore.instance.collection('library_books').doc(bookId).update({
          'copiesAvailable': currentAvailable - 1,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Book borrowed successfully! Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: $e', style: GoogleFonts.inter())),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Future<void> _returnBook(String transactionId, String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('library_transactions').doc(transactionId).update({
        'status': 'returned',
        'returnDate': FieldValue.serverTimestamp(),
      });
      
      final bookDoc = await FirebaseFirestore.instance.collection('library_books').doc(bookId).get();
      if (bookDoc.exists) {
        final bookData = bookDoc.data() as Map<String, dynamic>;
        final currentAvailable = bookData['copiesAvailable'] ?? 0;
        await FirebaseFirestore.instance.collection('library_books').doc(bookId).update({
          'copiesAvailable': currentAvailable + 1,
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Book returned successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e', style: GoogleFonts.inter())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
