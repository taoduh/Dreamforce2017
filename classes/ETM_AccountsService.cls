public with sharing class ETM_AccountsService {

    public static final Integer POSTAL_CODE_DIGITS = 5;

    public static Integer firstNumbersInString(String rawVal)
    {
        if (String.isBlank(rawVal)) return null;

        String nums = ETM_AccountsService.extractNumbers(rawVal);
        if (String.isBlank(nums)) return null;

        String firstDigits = (nums.length() < (POSTAL_CODE_DIGITS + 1) ? nums : nums.substring(0, POSTAL_CODE_DIGITS));
        return Integer.valueOf(firstDigits);
    }

    public static String extractNumbers(String rawVal)
    {
        String result = '';

        Matcher m = Pattern.compile('\\d+').matcher(rawVal);
        while (m.find())
        {
            result += m.group();
        }

        return result;
    }

    // TODO: where does this method belong?
    private static Map<String, String> visibleFieldToShadowField;
    public static Map<String, String> getVisibleFieldToShadowFieldMap()
    {
        if (visibleFieldToShadowField == null)
        {
            visibleFieldToShadowField = ETM_Utils.getCustomMetadataMap('Account_Visible_To_Shadow');
        }
        return visibleFieldToShadowField;
    }

    public static Account hydrateAccount(Id accountId)
    {
        Map<String, String> visibleFieldToShadowField = getVisibleFieldToShadowFieldMap();

        String visibleFields = String.join(new List<String>(visibleFieldToShadowField.keySet()), ', ');
        String shadowFields = String.join(visibleFieldToShadowField.values(), ', ');

        String soql = 'SELECT Id, ' +
            visibleFields + ', ' +
            shadowFields +
            ' FROM Account';

        List<Account> accounts = (List<Account>)Database.query(soql);
        if (accounts.size() == 0) return null;

        return accounts.get(0);
    }

    public static void updateAccountShadowFields(Account a)
    {
        visibleFieldToShadowField = getVisibleFieldToShadowFieldMap();

        // TODO: log this or email an administrator instead
        if (visibleFieldToShadowField == null) return;

        for (String visibleField : visibleFieldToShadowField.keySet())
        {
            String shadowField = visibleFieldToShadowField.get(visibleField);

            // TODO: log this or email an administrator instead
            if (String.isBlank(visibleField) || String.isBlank(shadowField)) continue;

            a.put(shadowField, a.get(visibleField));
        }
    }

}
