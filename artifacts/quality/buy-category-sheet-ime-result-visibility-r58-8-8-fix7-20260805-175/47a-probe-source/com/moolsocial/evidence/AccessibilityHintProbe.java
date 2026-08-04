package com.moolsocial.evidence;

import android.view.accessibility.AccessibilityNodeInfo;
import com.android.uiautomator.core.UiObject;
import com.android.uiautomator.core.UiSelector;
import com.android.uiautomator.testrunner.UiAutomatorTestCase;

public final class AccessibilityHintProbe extends UiAutomatorTestCase {
  private static final class NodeProbe extends UiObject {
    NodeProbe(UiSelector selector) {
      super(selector);
    }

    AccessibilityNodeInfo findNode(long timeoutMillis) {
      return findAccessibilityNodeInfo(timeoutMillis);
    }
  }

  public void testCategorySearchHintAndActions() throws Exception {
    Process launch = Runtime.getRuntime().exec(new String[] {
        "sh", "-c",
        "am force-stop com.moolsocial.app; "
            + "am start -n com.moolsocial.app/.MainActivity"
    });
    assertEquals("MoolSocial launch failed", 0, launch.waitFor());

    UiObject category = new UiObject(
        new UiSelector().descriptionStartsWith("Choose Shop category"));
    assertTrue("Shop category action did not become ready",
        category.waitForExists(12000));
    assertTrue("Shop category action did not open", category.click());

    NodeProbe field = new NodeProbe(
        new UiSelector().className("android.widget.EditText").instance(0));
    AccessibilityNodeInfo node = field.findNode(5000);
    assertNotNull("Category search EditText is missing", node);

    String hint = String.valueOf(node.getHintText());
    CharSequence rawText = node.getText();
    String text = rawText == null ? "" : rawText.toString();
    String description = String.valueOf(node.getContentDescription());
    boolean hasFocusAction = node.getActionList().contains(
        AccessibilityNodeInfo.AccessibilityAction.ACTION_FOCUS);
    boolean hasAccessibilityFocusAction = node.getActionList().contains(
        AccessibilityNodeInfo.AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS);
    boolean hasClickAction = node.getActionList().contains(
        AccessibilityNodeInfo.AccessibilityAction.ACTION_CLICK);
    boolean hasSetTextAction = node.getActionList().contains(
        AccessibilityNodeInfo.AccessibilityAction.ACTION_SET_TEXT);

    System.out.println("MOOLSOCIAL_ACCESSIBILITY_HINT_PROBE "
        + "class=" + node.getClassName()
        + "; hint=" + hint
        + "; text=" + text
        + "; contentDescription=" + description
        + "; focusable=" + node.isFocusable()
        + "; editable=" + node.isEditable()
        + "; hasFocusAction=" + hasFocusAction
        + "; hasAccessibilityFocusAction=" + hasAccessibilityFocusAction
        + "; hasClickAction=" + hasClickAction
        + "; hasSetTextAction=" + hasSetTextAction);

    assertEquals("Category search, Find a category", hint);
    assertEquals("", text);
    assertTrue("Category search must be focusable", node.isFocusable());
    assertTrue("Category search must be editable", node.isEditable());
    assertTrue("Category search must expose accessibility focus",
        hasAccessibilityFocusAction);
    assertTrue("Category search must expose click", hasClickAction);
    assertTrue("Category search must expose set-text", hasSetTextAction);
  }
}
