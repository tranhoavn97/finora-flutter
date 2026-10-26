import os
import re

dashboard_path = r'D:\FINORA-\flutter\lib\features\dashboard\dashboard_screen.dart'
demo_dashboard_path = r'D:\FINORA-\flutter\lib\features\catalog\screens\demo_dashboard_screen.dart'

with open(dashboard_path, 'r', encoding='utf-8') as f:
    dashboard_content = f.read()

with open(demo_dashboard_path, 'r', encoding='utf-8') as f:
    demo_content = f.read()

# We need to extract the new methods from demo_content
methods_to_extract = [
    r'(Widget _buildUnifiedHeroCockpit\(bool isDark\).*?)(?=\n  Widget _buildCockpitMetric)',
    r'(Widget _buildCockpitMetric\(.*?\) \{.*?\n  \})',
    r'(Widget _buildQuickActions\(bool isDark\).*?)(?=\n  Widget _buildAiQuickLogBar)',
    r'(Widget _buildAiQuickLogBar\(bool isDark\).*?)(?=\n  Widget _buildHealthScoreCard)',
    r'(Widget _buildHealthScoreCard\(bool isDark\).*?)(?=\n  Widget _healthMetricItem)',
    r'(Widget _healthMetricItem\(.*?\) \{.*?\n  \})',
    r'(Widget _buildWealthSection\(bool isDark\).*?)(?=\n  Widget _buildRecentTransactionsSection)',
    r'(Widget _buildRecentTransactionsSection\(bool isDark\).*?)(?=\n  Widget _buildDateHeader)',
    r'(Widget _buildDateHeader\(.*?\) \{.*?\n  \})',
    r'(Widget _buildTransactionItem\(.*?\) \{.*?\n  \})',
]

extracted_methods_code = []
for pattern in methods_to_extract:
    match = re.search(pattern, demo_content, re.DOTALL)
    if match:
        # We need to replace CatalogMockData with `d.` or variables
        code = match.group(1)
        code = code.replace("bool isDark", "BuildContext context, DashboardData d, bool isDark")
        code = code.replace("CatalogMockData.totalNetWorth", "(d.totalWalletBalance + d.totalAssetsValue - d.totalCreditCardDebt)")
        code = code.replace("CatalogMockData.periodIncome", "d.periodIncome")
        code = code.replace("CatalogMockData.periodExpense", "d.periodExpense")
        code = code.replace("CatalogMockData.periodNet", "d.periodNet")
        code = code.replace("CatalogMockData.emergencyFundMonths", "d.emergencyRunwayMonths")
        code = code.replace("CatalogMockData.savingRatio", "(d.savingsRatePercent / 100)")
        code = code.replace("CatalogMockData.debtRatio", "(d.debtRatioPercent / 100)")
        code = code.replace("CatalogMockData.wallets", "d.wallets")
        code = code.replace("_selectedDateFilterIndex", "d.selectedDateFilter.index")
        
        # for transactions
        code = code.replace("_recentTransactions", "d.recentTransactions")
        code = code.replace("CatalogTransactionItem", "TransactionModel")
        
        extracted_methods_code.append(code)

new_methods_string = "\n\n  ".join(extracted_methods_code)

# Let's find the build method in dashboard_screen.dart and replace its contents
build_method_pattern = r'(Widget build\(BuildContext context\) \{.*?)(?=  Widget _buildHeroCard)'
match_build = re.search(build_method_pattern, dashboard_content, re.DOTALL)

if match_build:
    new_build = match_build.group(1)
    # Rewrite the child of the column inside build
    new_build = re.sub(
        r'child: Column\(\s*crossAxisAlignment: CrossAxisAlignment\.stretch,\s*children: \[.*?_buildRecentTransactions\(context, d, isDark, studio\),\s*\],\s*\),',
        '''child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUnifiedHeroCockpit(context, d, isDark),
                const SizedBox(height: 14),
                _buildAiQuickLogBar(context, d, isDark),
                const SizedBox(height: 14),
                _buildHealthScoreCard(context, d, isDark),
                const SizedBox(height: 14),
                _buildWealthSection(context, d, isDark),
                const SizedBox(height: 14),
                _buildRecentTransactionsSection(context, d, isDark),
              ],
            ),''',
        new_build,
        flags=re.DOTALL
    )
    
    # We replace from the beginning of build to the end of the file with our new methods
    start_index = match_build.start()
    
    final_content = dashboard_content[:start_index] + new_build + "  " + new_methods_string + "\n}\n"
    
    with open(dashboard_path, 'w', encoding='utf-8') as f:
        f.write(final_content)
    
    print("Dashboard patched successfully.")
else:
    print("Could not find build method.")
