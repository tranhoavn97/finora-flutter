import 'package:flutter_test/flutter_test.dart';
import '../lib/data/services/copilot_action_service.dart';
void main() {
 final now=DateTime.now(); final month='${now.year}-${now.month.toString().padLeft(2,'0')}';
 final data=<String,List<Map<String,dynamic>>>{'transactions':[{'id':'tx1','note':'Ăn phở','amount':45000,'type':'expense','date':1}],'budgets':[{'id':'b1','categoryName':'Ăn uống','limitAmount':2000000,'monthKey':month}],'goals':[{'id':'g1','name':'Mua nhà','targetAmount':500000000,'savedAmount':100000000}]};
 test('Budget proposal preserves source and shows before/after',(){final a=CopilotActionService.plan('Sửa ngân sách Ăn uống thành 3 triệu',data);expect(a.before,2000000);expect(a.value,3000000);expect(data['budgets']!.first['limitAmount'],2000000);});
 test('Transaction amount and note edits',(){expect(CopilotActionService.plan('Sửa giao dịch Ăn phở thành 50k',data).value,50000);expect(CopilotActionService.plan('Đổi ghi chú tx1 thành "Bữa sáng"',data).value,'Bữa sáng');});
 test('Cannot change accumulated money or lower target below saved',(){expect(()=>CopilotActionService.validate('goals','g1','savedAmount',1,data),throwsStateError);expect(()=>CopilotActionService.plan('Sửa mục tiêu Mua nhà thành 50 triệu',data),throwsStateError);});
 test('Advice is not a change request',(){expect(CopilotActionService.isEditRequest('Mẹo cắt giảm 10% chi phí'),false);});
 test('Unknown target and zero amount are rejected',(){expect(()=>CopilotActionService.validate('budgets','unknown','limitAmount',1,data),throwsStateError);expect(()=>CopilotActionService.validate('budgets','b1','limitAmount',0,data),throwsStateError);});
}
