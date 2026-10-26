List<Map<String,dynamic>> demoRows(String collection) {
final now=DateTime.now();final date=now.millisecondsSinceEpoch;
final month='${now.year}-${now.month.toString().padLeft(2,'0')}';
final data=<String,List<Map<String,dynamic>>>{
'wallets':[
{'id':'cash','name':'Tiền mặt','type':'cash','initialBalance':2500000,'balance':2500000,'owner':'husband'},
{'id':'bank','name':'Vietcombank','type':'bank','bankCode':'VCB','initialBalance':18000000,'balance':18000000,'owner':'husband'},
{'id':'card','name':'Thẻ tín dụng','type':'credit_card','creditLimit':50000000,'initialDebt':3500000,'currentDebt':3500000,'statementDay':20,'paymentDueDay':5}],
'categories':[
{'id':'food','name':'Ăn uống','type':'expense','group':'expense','icon':'restaurant','color':'#F59E0B'},
{'id':'shop','name':'Mua sắm','type':'expense','group':'expense','icon':'shopping_bag','color':'#8B5CF6'},
{'id':'salary','name':'Lương','type':'income','group':'income','icon':'payments','color':'#10B981'}],
'transactions':[
{'id':'tx1','amount':65000,'type':'expense','date':date,'categoryId':'food','categoryName':'Ăn uống','walletId':'cash','walletName':'Tiền mặt','note':'Bữa trưa','owner':'husband'},
{'id':'tx2','amount':450000,'type':'expense','date':date-86400000,'categoryId':'shop','categoryName':'Mua sắm','walletId':'bank','walletName':'Vietcombank','note':'Đồ dùng gia đình','owner':'husband'},
{'id':'tx3','amount':22000000,'type':'income','date':date-172800000,'categoryId':'salary','categoryName':'Lương','walletId':'bank','walletName':'Vietcombank','note':'Lương tháng','owner':'husband'}],
'budgets':[{'id':'budget','categoryId':'food','categoryName':'Ăn uống','limitAmount':4000000,'monthKey':month,'isRecurring':false}],
'goals':[{'id':'goal','name':'Quỹ dự phòng','targetAmount':50000000,'savedAmount':18000000,'status':'active','targetDate':date+15552000000}],
'assets':[{'id':'asset','name':'Quỹ đầu tư','type':'fund','quantity':100,'currentPrice':120000,'purchasePrice':100000,'currentValue':12000000}],
'loans':[{'id':'loan','name':'Khoản vay mẫu','personName':'Minh','type':'lent','amount':5000000,'remainingAmount':3500000,'dueDate':date+604800000,'status':'active'}],
'notifications':[{'id':'notice','title':'Nhắc ngân sách','message':'Kiểm tra kế hoạch chi tiêu tháng này','type':'info','isRead':false,'createdAt':date}],
};
return (data[collection]??[]).map((v)=><String,dynamic>{'userId':'demo','createdAt':date,'updatedAt':date,...v}).toList();
}
