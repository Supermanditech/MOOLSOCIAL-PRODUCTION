import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'package:flutter/foundation.dart';
import '../chat/chat_models.dart' show ChatAttachmentKind;
import '../chat/chat_services.dart'
    show ChatAttachmentPicker, ChatVoiceRecorder;
import '../work/work_services.dart'
    show WorkPickedProof, WorkProofPicker, WorkProofSource;

/// Task labels only, sourced from the audited Public/Store inventory.
/// These are not enabled backend tools or domain permission grants.
const moolAssistantActions = <MoolAssistantAction>[
  MoolAssistantAction("AI-ACT-001", "Shopping", "Find a product"),
  MoolAssistantAction("AI-ACT-002", "Shopping", "Browse products by category"),
  MoolAssistantAction("AI-ACT-003", "Shopping", "Filter and sort products"),
  MoolAssistantAction(
    "AI-ACT-004",
    "Shopping",
    "Find Wholesale or Bulk products",
  ),
  MoolAssistantAction("AI-ACT-005", "Shopping", "Change my shopping area"),
  MoolAssistantAction(
    "AI-ACT-006",
    "Shopping",
    "Show product and supplier details",
  ),
  MoolAssistantAction(
    "AI-ACT-007",
    "Shopping",
    "Choose a product size, pack or variant",
  ),
  MoolAssistantAction(
    "AI-ACT-008",
    "Shopping",
    "Compare products and suppliers",
  ),
  MoolAssistantAction("AI-ACT-009", "Shopping", "Save or unsave a product"),
  MoolAssistantAction("AI-ACT-010", "Shopping", "Show my saved products"),
  MoolAssistantAction("AI-ACT-011", "Shopping", "Clear my saved products"),
  MoolAssistantAction(
    "AI-ACT-012",
    "Shopping",
    "Clear recently viewed products",
  ),
  MoolAssistantAction("AI-ACT-013", "Shopping", "Clear recent searches"),
  MoolAssistantAction("AI-ACT-014", "Shopping", "Add products to my cart"),
  MoolAssistantAction("AI-ACT-015", "Shopping", "Schedule a product purchase"),
  MoolAssistantAction("AI-ACT-016", "Shopping", "Prepare my monthly basket"),
  MoolAssistantAction("AI-ACT-017", "Shopping", "Buy this product"),
  MoolAssistantAction("AI-ACT-018", "Shopping", "Change quantities in my cart"),
  MoolAssistantAction(
    "AI-ACT-019",
    "Shopping",
    "Remove a product from my cart",
  ),
  MoolAssistantAction("AI-ACT-020", "Shopping", "Clear this cart"),
  MoolAssistantAction(
    "AI-ACT-021",
    "Shopping",
    "Apply an eligible Store coupon",
  ),
  MoolAssistantAction(
    "AI-ACT-022",
    "Shopping",
    "Remove an applied Store coupon",
  ),
  MoolAssistantAction(
    "AI-ACT-023",
    "Shopping",
    "Choose an eligible cart offer",
  ),
  MoolAssistantAction("AI-ACT-024", "Shopping", "Choose a delivery address"),
  MoolAssistantAction("AI-ACT-025", "Shopping", "Add a delivery address"),
  MoolAssistantAction("AI-ACT-026", "Shopping", "Edit a delivery address"),
  MoolAssistantAction("AI-ACT-027", "Shopping", "Remove a delivery address"),
  MoolAssistantAction(
    "AI-ACT-028",
    "Shopping",
    "Choose delivery or collection",
  ),
  MoolAssistantAction(
    "AI-ACT-029",
    "Shopping",
    "Prepare a Store collection order",
  ),
  MoolAssistantAction("AI-ACT-030", "Shopping", "Add delivery instructions"),
  MoolAssistantAction("AI-ACT-031", "Shopping", "Set a delivery tip"),
  MoolAssistantAction(
    "AI-ACT-032",
    "Shopping",
    "Add my purchase-order reference",
  ),
  MoolAssistantAction(
    "AI-ACT-033",
    "Shopping",
    "Choose an available payment method",
  ),
  MoolAssistantAction(
    "AI-ACT-034",
    "Shopping",
    "Show my supplier-assigned payment terms",
  ),
  MoolAssistantAction(
    "AI-ACT-035",
    "Shopping",
    "Explain this purchase's payment terms",
  ),
  MoolAssistantAction(
    "AI-ACT-036",
    "Shopping",
    "Attach a prescription for medicines",
  ),
  MoolAssistantAction("AI-ACT-037", "Shopping", "Review and place my order"),
  MoolAssistantAction(
    "AI-ACT-038",
    "Shopping",
    "Review changed prices before ordering",
  ),
  MoolAssistantAction(
    "AI-ACT-039",
    "Shopping",
    "Review changed delivery details",
  ),
  MoolAssistantAction(
    "AI-ACT-040",
    "Shopping",
    "Continue an unfinished payment",
  ),
  MoolAssistantAction(
    "AI-ACT-041",
    "Shopping",
    "Check whether my payment succeeded",
  ),
  MoolAssistantAction(
    "AI-ACT-042",
    "Shopping",
    "Record that I sent a bank transfer",
  ),
  MoolAssistantAction("AI-ACT-043", "Shopping", "Show my orders"),
  MoolAssistantAction("AI-ACT-044", "Shopping", "Track my order"),
  MoolAssistantAction(
    "AI-ACT-045",
    "Shopping",
    "Show the products in my order",
  ),
  MoolAssistantAction("AI-ACT-046", "Shopping", "Buy an earlier order again"),
  MoolAssistantAction("AI-ACT-047", "Shopping", "Change order notifications"),
  MoolAssistantAction(
    "AI-ACT-048",
    "Shopping",
    "Request another delivery slot",
  ),
  MoolAssistantAction(
    "AI-ACT-049",
    "Shopping",
    "Review a proposed replacement",
  ),
  MoolAssistantAction(
    "AI-ACT-050",
    "Shopping",
    "Request an order cancellation, return, refund or replacement",
  ),
  MoolAssistantAction(
    "AI-ACT-051",
    "Shopping",
    "Report an incorrect delivery confirmation",
  ),
  MoolAssistantAction(
    "AI-ACT-052",
    "Shopping",
    "Pay the remaining order balance",
  ),
  MoolAssistantAction(
    "AI-ACT-053",
    "Shopping",
    "Confirm collection of my order",
  ),
  MoolAssistantAction("AI-ACT-054", "Shopping", "Write a product review"),
  MoolAssistantAction("AI-ACT-055", "Shopping", "Rate a purchase privately"),
  MoolAssistantAction("AI-ACT-056", "Shopping", "Report a product"),
  MoolAssistantAction(
    "AI-ACT-057",
    "Shopping",
    "Refresh the current order status",
  ),
  MoolAssistantAction(
    "AI-ACT-058",
    "Shopping",
    "Recover an interrupted cart or checkout",
  ),
  MoolAssistantAction(
    "AI-ACT-059",
    "Shopping",
    "Recheck unavailable cart items",
  ),
  MoolAssistantAction(
    "AI-ACT-060",
    "Shopping",
    "Request the latest listed trade price",
  ),
  MoolAssistantAction(
    "AI-ACT-061",
    "Social",
    "Find a person, topic, post or video",
  ),
  MoolAssistantAction("AI-ACT-062", "Social", "Show my Feed"),
  MoolAssistantAction("AI-ACT-063", "Social", "Search public videos"),
  MoolAssistantAction("AI-ACT-064", "Social", "Open a Short"),
  MoolAssistantAction("AI-ACT-065", "Social", "Play a video"),
  MoolAssistantAction("AI-ACT-066", "Social", "Show video details"),
  MoolAssistantAction("AI-ACT-067", "Social", "Show the video's channel"),
  MoolAssistantAction("AI-ACT-068", "Social", "Show a creator's profile"),
  MoolAssistantAction("AI-ACT-069", "Social", "Like or unlike a post"),
  MoolAssistantAction("AI-ACT-070", "Social", "Save or unsave a post"),
  MoolAssistantAction("AI-ACT-071", "Social", "Show my saved posts"),
  MoolAssistantAction("AI-ACT-072", "Social", "Read comments and replies"),
  MoolAssistantAction("AI-ACT-073", "Social", "Write a comment or reply"),
  MoolAssistantAction("AI-ACT-074", "Social", "Follow or unfollow a creator"),
  MoolAssistantAction("AI-ACT-075", "Social", "Repost or undo a repost"),
  MoolAssistantAction(
    "AI-ACT-076",
    "Social",
    "Share a post outside MoolSocial",
  ),
  MoolAssistantAction("AI-ACT-077", "Social", "Vote in a poll or quiz"),
  MoolAssistantAction("AI-ACT-078", "Social", "Report a post"),
  MoolAssistantAction("AI-ACT-079", "Social", "Block or unblock an account"),
  MoolAssistantAction("AI-ACT-080", "Social", "Show my notifications"),
  MoolAssistantAction("AI-ACT-081", "Social", "Mark a notification as read"),
  MoolAssistantAction("AI-ACT-082", "Social", "Create a text post"),
  MoolAssistantAction("AI-ACT-083", "Social", "Create a photo post"),
  MoolAssistantAction("AI-ACT-084", "Social", "Create a photo carousel"),
  MoolAssistantAction("AI-ACT-085", "Social", "Create a text poll"),
  MoolAssistantAction("AI-ACT-086", "Social", "Create an image poll"),
  MoolAssistantAction("AI-ACT-087", "Social", "Create a quiz"),
  MoolAssistantAction("AI-ACT-088", "Social", "Prepare a Reel or Short"),
  MoolAssistantAction(
    "AI-ACT-089",
    "Social",
    "Preview my post before publishing",
  ),
  MoolAssistantAction("AI-ACT-090", "Social", "Save an unfinished post"),
  MoolAssistantAction("AI-ACT-091", "Social", "Continue an unfinished post"),
  MoolAssistantAction("AI-ACT-092", "Social", "Discard an unfinished post"),
  MoolAssistantAction("AI-ACT-093", "Social", "Publish my prepared post"),
  MoolAssistantAction("AI-ACT-094", "Social", "Ask to message a creator"),
  MoolAssistantAction("AI-ACT-095", "Chat", "Find a conversation"),
  MoolAssistantAction("AI-ACT-096", "Chat", "Read messages in a conversation"),
  MoolAssistantAction(
    "AI-ACT-097",
    "Chat",
    "Start a conversation with someone",
  ),
  MoolAssistantAction("AI-ACT-098", "Chat", "Draft a message in my language"),
  MoolAssistantAction("AI-ACT-099", "Chat", "Reply to a particular message"),
  MoolAssistantAction("AI-ACT-100", "Chat", "Send my prepared message"),
  MoolAssistantAction("AI-ACT-101", "Chat", "Attach a photo to a message"),
  MoolAssistantAction(
    "AI-ACT-102",
    "Chat",
    "Attach a file or video to a message",
  ),
  MoolAssistantAction("AI-ACT-103", "Chat", "Record a voice message"),
  MoolAssistantAction("AI-ACT-104", "Chat", "Send my prepared attachment"),
  MoolAssistantAction("AI-ACT-105", "Chat", "React to a message"),
  MoolAssistantAction("AI-ACT-106", "Chat", "Forward a message"),
  MoolAssistantAction("AI-ACT-107", "Chat", "Hide a message from my view"),
  MoolAssistantAction("AI-ACT-108", "Chat", "Pin or unpin a conversation"),
  MoolAssistantAction(
    "AI-ACT-109",
    "Chat",
    "Archive or unarchive a conversation",
  ),
  MoolAssistantAction("AI-ACT-110", "Chat", "Mute or unmute a conversation"),
  MoolAssistantAction("AI-ACT-111", "Chat", "Mark a conversation as read"),
  MoolAssistantAction("AI-ACT-112", "Chat", "Clear conversation messages"),
  MoolAssistantAction(
    "AI-ACT-113",
    "Chat",
    "Accept or decline a message request",
  ),
  MoolAssistantAction("AI-ACT-114", "Chat", "Block or unblock someone in Chat"),
  MoolAssistantAction("AI-ACT-115", "Chat", "Change my Chat privacy settings"),
  MoolAssistantAction("AI-ACT-116", "Chat", "Change my Chat notifications"),
  MoolAssistantAction("AI-ACT-117", "Chat", "Change who can call me"),
  MoolAssistantAction("AI-ACT-118", "Chat", "Start a voice or video call"),
  MoolAssistantAction(
    "AI-ACT-119",
    "Chat",
    "Answer or decline an incoming call",
  ),
  MoolAssistantAction("AI-ACT-120", "Chat", "End my current call"),
  MoolAssistantAction("AI-ACT-121", "Chat", "Show a group's details"),
  MoolAssistantAction("AI-ACT-122", "Chat", "Invite someone to a group"),
  MoolAssistantAction("AI-ACT-123", "Chat", "Change group permissions"),
  MoolAssistantAction("AI-ACT-124", "Chat", "Leave a group"),
  MoolAssistantAction(
    "AI-ACT-125",
    "Chat",
    "Accept or decline a group invitation",
  ),
  MoolAssistantAction(
    "AI-ACT-126",
    "Chat",
    "Check or recover an interrupted message",
  ),
  MoolAssistantAction("AI-ACT-127", "Food", "Find a restaurant"),
  MoolAssistantAction("AI-ACT-128", "Food", "Find a dish or browse a menu"),
  MoolAssistantAction("AI-ACT-129", "Food", "Choose meal options and add-ons"),
  MoolAssistantAction("AI-ACT-130", "Food", "Add food to my cart"),
  MoolAssistantAction(
    "AI-ACT-131",
    "Food",
    "Change food quantities in my cart",
  ),
  MoolAssistantAction("AI-ACT-132", "Food", "Remove food from my cart"),
  MoolAssistantAction("AI-ACT-133", "Food", "Choose food delivery or pickup"),
  MoolAssistantAction("AI-ACT-134", "Food", "Choose when to receive my food"),
  MoolAssistantAction("AI-ACT-135", "Food", "Set the food delivery address"),
  MoolAssistantAction("AI-ACT-136", "Food", "Choose how to pay for food"),
  MoolAssistantAction("AI-ACT-137", "Food", "Review and place my food order"),
  MoolAssistantAction("AI-ACT-138", "Food", "Track my food order"),
  MoolAssistantAction("AI-ACT-139", "Food", "Request food-order cancellation"),
  MoolAssistantAction("AI-ACT-140", "Food", "View my food-order invoice"),
  MoolAssistantAction("AI-ACT-141", "Food", "Rate my food order"),
  MoolAssistantAction(
    "AI-ACT-142",
    "Food",
    "Choose restaurant, party size and table preferences",
  ),
  MoolAssistantAction("AI-ACT-143", "Food", "Choose a table booking time"),
  MoolAssistantAction("AI-ACT-144", "Food", "Review and book a table"),
  MoolAssistantAction("AI-ACT-145", "Food", "Cancel a table booking"),
  MoolAssistantAction("AI-ACT-146", "Travel", "Set my pickup and destination"),
  MoolAssistantAction("AI-ACT-147", "Travel", "Choose Bike, Auto or Cab"),
  MoolAssistantAction("AI-ACT-148", "Travel", "Choose a ride package"),
  MoolAssistantAction("AI-ACT-149", "Travel", "Schedule a ride"),
  MoolAssistantAction("AI-ACT-150", "Travel", "Add pickup instructions"),
  MoolAssistantAction("AI-ACT-151", "Travel", "Review and book my ride"),
  MoolAssistantAction("AI-ACT-152", "Travel", "Cancel my ride"),
  MoolAssistantAction("AI-ACT-153", "Travel", "Review an added ride stop"),
  MoolAssistantAction("AI-ACT-154", "Travel", "Choose a ride payment method"),
  MoolAssistantAction("AI-ACT-155", "Travel", "Review and pay my ride fare"),
  MoolAssistantAction("AI-ACT-156", "Travel", "Rate my trip"),
  MoolAssistantAction(
    "AI-ACT-157",
    "Travel",
    "Report a ride issue or lost item",
  ),
  MoolAssistantAction(
    "AI-ACT-158",
    "Travel",
    "Find buses for my route and date",
  ),
  MoolAssistantAction(
    "AI-ACT-159",
    "Travel",
    "Select a bus to review its journey details",
  ),
  MoolAssistantAction("AI-ACT-160", "Care", "Find a doctor for my needs"),
  MoolAssistantAction(
    "AI-ACT-161",
    "Care",
    "Choose consultation type and symptoms",
  ),
  MoolAssistantAction(
    "AI-ACT-162",
    "Care",
    "Choose who the consultation is for",
  ),
  MoolAssistantAction(
    "AI-ACT-163",
    "Care",
    "Enter a child's details for consultation",
  ),
  MoolAssistantAction("AI-ACT-164", "Care", "Choose medical reports to share"),
  MoolAssistantAction("AI-ACT-165", "Care", "Review consultation consent"),
  MoolAssistantAction("AI-ACT-166", "Care", "Review my consultation details"),
  MoolAssistantAction("AI-ACT-167", "Care", "Join using a clinic invitation"),
  MoolAssistantAction("AI-ACT-168", "Care", "Choose a follow-up appointment"),
  MoolAssistantAction("AI-ACT-169", "Care", "Attach a follow-up report"),
  MoolAssistantAction("AI-ACT-170", "Care", "Change medicine reminders"),
  MoolAssistantAction(
    "AI-ACT-171",
    "Care",
    "Find medicines and prepare a medicine purchase",
  ),
  MoolAssistantAction("AI-ACT-172", "Care", "Find a salon service"),
  MoolAssistantAction(
    "AI-ACT-173",
    "Care",
    "Choose salon services and add-ons",
  ),
  MoolAssistantAction(
    "AI-ACT-174",
    "Care",
    "Choose a salon visit or home service",
  ),
  MoolAssistantAction("AI-ACT-175", "Care", "Review and book my salon service"),
  MoolAssistantAction("AI-ACT-176", "Care", "Cancel my salon booking"),
  MoolAssistantAction(
    "AI-ACT-177",
    "Care",
    "Check in for my salon appointment",
  ),
  MoolAssistantAction("AI-ACT-178", "Care", "Review and pay my salon bill"),
  MoolAssistantAction("AI-ACT-179", "Care", "Rate my salon visit"),
  MoolAssistantAction("AI-ACT-180", "Care", "Report a salon booking issue"),
  MoolAssistantAction("AI-ACT-181", "Work", "Find work opportunities"),
  MoolAssistantAction(
    "AI-ACT-182",
    "Work",
    "Filter work by area and requirements",
  ),
  MoolAssistantAction(
    "AI-ACT-183",
    "Work",
    "Show a work opportunity's details",
  ),
  MoolAssistantAction(
    "AI-ACT-184",
    "Work",
    "Save or unsave a work opportunity",
  ),
  MoolAssistantAction(
    "AI-ACT-185",
    "Work",
    "Review and apply for an opportunity",
  ),
  MoolAssistantAction("AI-ACT-186", "Work", "Withdraw a work application"),
  MoolAssistantAction(
    "AI-ACT-187",
    "Work",
    "Show my applications and Workspaces",
  ),
  MoolAssistantAction("AI-ACT-188", "Work", "Continue a Workspace application"),
  MoolAssistantAction(
    "AI-ACT-189",
    "Work",
    "Choose the Workspace I want to apply for",
  ),
  MoolAssistantAction(
    "AI-ACT-190",
    "Work",
    "Prepare my Workspace application details",
  ),
  MoolAssistantAction("AI-ACT-191", "Work", "Attach application documents"),
  MoolAssistantAction(
    "AI-ACT-192",
    "Work",
    "Review and submit my Workspace application",
  ),
  MoolAssistantAction("AI-ACT-193", "Work", "Check my application status"),
  MoolAssistantAction("AI-ACT-194", "Work", "Correct a returned application"),
  MoolAssistantAction(
    "AI-ACT-195",
    "Work",
    "Open one of my approved Workspaces",
  ),
  MoolAssistantAction(
    "AI-ACT-196",
    "Account and files",
    "View my personal profile",
  ),
  MoolAssistantAction(
    "AI-ACT-197",
    "Account and files",
    "Change my display name",
  ),
  MoolAssistantAction(
    "AI-ACT-198",
    "Account and files",
    "Change my service area",
  ),
  MoolAssistantAction(
    "AI-ACT-199",
    "Account and files",
    "Use my current location",
  ),
  MoolAssistantAction(
    "AI-ACT-200",
    "Account and files",
    "Change my app language preference",
  ),
  MoolAssistantAction(
    "AI-ACT-201",
    "Account and files",
    "Change app notification preferences",
  ),
  MoolAssistantAction(
    "AI-ACT-202",
    "Account and files",
    "Open accessibility settings",
  ),
  MoolAssistantAction(
    "AI-ACT-203",
    "Account and files",
    "Read the privacy policy",
  ),
  MoolAssistantAction(
    "AI-ACT-204",
    "Account and files",
    "View my sign-in methods",
  ),
  MoolAssistantAction(
    "AI-ACT-205",
    "Account and files",
    "Manage app permissions",
  ),
  MoolAssistantAction(
    "AI-ACT-206",
    "Account and files",
    "Sign in to my account",
  ),
  MoolAssistantAction(
    "AI-ACT-207",
    "Account and files",
    "Sign out of this account",
  ),
  MoolAssistantAction(
    "AI-ACT-208",
    "Account and files",
    "Find my downloaded invoices and reports",
  ),
  MoolAssistantAction(
    "AI-ACT-209",
    "Account and files",
    "Find my saved documents",
  ),
  MoolAssistantAction(
    "AI-ACT-210",
    "Account and files",
    "View or manage subscription plans",
  ),
  MoolAssistantAction(
    "AI-ACT-211",
    "Account and files",
    "Ask for help or report an app issue",
  ),
  MoolAssistantAction(
    "AI-ACT-212",
    "Account and files",
    "Switch between public sections",
  ),
  MoolAssistantAction(
    "AI-ACT-213",
    "Products",
    "Add a product to my Store",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-214",
    "Products",
    "Edit a product's details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-215",
    "Products",
    "Add or edit product variants and packs",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-216",
    "Products",
    "Add or change product photos",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-217",
    "Products",
    "Upload prepared product media",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-218",
    "Products",
    "View default product settings",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-219",
    "Products",
    "Change default product settings",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-220",
    "Products",
    "Confirm a current commodity price",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-221",
    "Products",
    "Update a product's sale prices",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-222",
    "Products",
    "List or withdraw a product from public sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-223",
    "Products",
    "Submit a product for publication",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-224",
    "Products",
    "Submit a product variant family",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-225",
    "Products",
    "Check a product's publication status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-226",
    "Products",
    "Pause Counter sale for a product",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-227",
    "Products",
    "Resume Counter sale for a product",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-228",
    "Products",
    "Import product entries",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-229",
    "Products",
    "Find a product in the master catalogue",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-230",
    "Products",
    "Preview a product as a customer",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-231",
    "Stock and receiving",
    "Check stock in my Store",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-232",
    "Stock and receiving",
    "Show stock movements for an item and period",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-233",
    "Stock and receiving",
    "Adjust an item's stock quantity",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-234",
    "Stock and receiving",
    "Restock from Wholesale or Bulk suppliers",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-235",
    "Stock and receiving",
    "Add a new supplier",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-236",
    "Stock and receiving",
    "Find an existing supplier",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-237",
    "Stock and receiving",
    "Edit a supplier's details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-238",
    "Stock and receiving",
    "Prepare a goods-receipt entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-239",
    "Stock and receiving",
    "Add items to a goods-receipt entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-240",
    "Stock and receiving",
    "Choose a stock item for receiving",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-241",
    "Stock and receiving",
    "Scan a supplier document",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-242",
    "Stock and receiving",
    "Review extracted and extra printed fields",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-243",
    "Stock and receiving",
    "Continue an unfinished goods-receipt entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-244",
    "Stock and receiving",
    "Confirm the quantities actually received",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-245",
    "Stock and receiving",
    "Link received goods to a supplier bill",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-246",
    "Stock and receiving",
    "Record batch, pack and printed dates",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-247",
    "Stock and receiving",
    "Record goods returned to a supplier",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-248",
    "Stock and receiving",
    "Record a shortage or damaged delivery",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-249",
    "Stock and receiving",
    "Check a shortage record's status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-250",
    "Stock and receiving",
    "Check a supplier goods-return record",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-251",
    "Stock and receiving",
    "Recover interrupted Restock receiving",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-252",
    "Purchases and supplier accounts",
    "Record a supplier purchase bill",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-253",
    "Purchases and supplier accounts",
    "Find a saved purchase bill",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-254",
    "Purchases and supplier accounts",
    "View a saved purchase invoice",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-255",
    "Purchases and supplier accounts",
    "Download a recorded purchase document",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-256",
    "Purchases and supplier accounts",
    "Confirm a bill in the supplier account",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-257",
    "Purchases and supplier accounts",
    "Record supplier opening dues",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-258",
    "Purchases and supplier accounts",
    "Confirm supplier opening dues",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-259",
    "Purchases and supplier accounts",
    "Record a supplier payment",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-260",
    "Purchases and supplier accounts",
    "Record an advance paid to a supplier",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-261",
    "Purchases and supplier accounts",
    "Record an on-account supplier payment",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-262",
    "Purchases and supplier accounts",
    "Apply a payment or credit to a bill",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-263",
    "Purchases and supplier accounts",
    "Check a payment allocation's status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-264",
    "Purchases and supplier accounts",
    "Record a supplier GST or commercial credit note",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-265",
    "Purchases and supplier accounts",
    "Check a recorded supplier credit note",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-266",
    "Purchases and supplier accounts",
    "Record a supplier refund received",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-267",
    "Purchases and supplier accounts",
    "Check a supplier refund record",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-268",
    "Purchases and supplier accounts",
    "View a supplier's ledger",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-269",
    "Purchases and supplier accounts",
    "Open available purchase-management actions",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-270",
    "Purchases and supplier accounts",
    "Record a Store expense",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-271",
    "Purchases and supplier accounts",
    "Record a Store money-register entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-272",
    "Purchases and supplier accounts",
    "Trace a stock movement to its purchase",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-273",
    "Orders and fulfilment",
    "Find Store orders by status or period",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-274",
    "Orders and fulfilment",
    "Show an order and its original documents",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-275",
    "Orders and fulfilment",
    "Accept or reject an incoming order",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-276",
    "Orders and fulfilment",
    "Request more time for an order",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-277",
    "Orders and fulfilment",
    "Prepare an order issue response",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-278",
    "Orders and fulfilment",
    "Send an order issue response",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-279",
    "Orders and fulfilment",
    "Check whether an issue response was sent",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-280",
    "Orders and fulfilment",
    "Record picked or packed quantities",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-281",
    "Orders and fulfilment",
    "Advance an order to its permitted next stage",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-282",
    "Orders and fulfilment",
    "Confirm customer pickup",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-283",
    "Orders and fulfilment",
    "Confirm goods handed over",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-284",
    "Orders and fulfilment",
    "Check or retry delivery assignment",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-285",
    "Orders and fulfilment",
    "Cancel a Store order",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-286",
    "Orders and fulfilment",
    "Recover an interrupted order action",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-287",
    "Orders and fulfilment",
    "Prepare a repeat customer order",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-288",
    "Sales and customers",
    "Start or resume a counter sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-289",
    "Sales and customers",
    "Add items and customer details to a counter sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-290",
    "Sales and customers",
    "Set a counter-sale discount",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-291",
    "Sales and customers",
    "Review and complete a counter sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-292",
    "Sales and customers",
    "Discard an unfinished counter sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-293",
    "Sales and customers",
    "View a sales invoice",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-294",
    "Sales and customers",
    "View a sales statement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-295",
    "Sales and customers",
    "Share a sales invoice",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-296",
    "Sales and customers",
    "Find a customer and their account",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-297",
    "Sales and customers",
    "View customer activity for a period",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-298",
    "Sales and customers",
    "Record that I contacted a customer",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-299",
    "Sales and customers",
    "Record money received from a customer",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-300",
    "Sales and customers",
    "Check a customer payment's recorded status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-301",
    "Sales and customers",
    "Record a customer sales return",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-302",
    "Sales and customers",
    "Check a sales return's status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-303",
    "Sales and customers",
    "Record a customer refund paid",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-304",
    "Sales and customers",
    "Check a customer refund's status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-305",
    "Sales and customers",
    "Apply customer credit to a sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-307",
    "Sales and customers",
    "Review a supported sales exchange",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-308",
    "Offers, finance and reports",
    "View my Store coupons",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-309",
    "Offers, finance and reports",
    "Create or edit a Store coupon",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-310",
    "Offers, finance and reports",
    "Publish or pause a Store coupon",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-311",
    "Offers, finance and reports",
    "Request a business-finance callback",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-312",
    "Offers, finance and reports",
    "Show my Store reports",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-313",
    "Offers, finance and reports",
    "Choose a report period",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-314",
    "Offers, finance and reports",
    "Download a Store analytics report",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-315",
    "Offers, finance and reports",
    "Show a sales or outstanding statement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-316",
    "Offers, finance and reports",
    "Check or request a supplier settlement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-317",
    "Store settings",
    "Switch to another authorised Store",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-318",
    "Store settings",
    "Change Store availability",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-319",
    "Store settings",
    "Change Store trading controls",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-320",
    "Store settings",
    "Edit public Store details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-321",
    "Store settings",
    "Publish reviewed public Store details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-322",
    "Store settings",
    "Change Store delivery and pickup settings",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-323",
    "Store settings",
    "Change invoice delivery preferences",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-324",
    "Store settings",
    "Change the Store's payment destination",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-326",
    "Store settings",
    "Change supported Store staff settings",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-327",
    "Store settings",
    "Change public stock or Store visibility",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-328",
    "Store settings",
    "Dismiss a Store alert",
    store: true,
  ),
  MoolAssistantAction("AI-ACT-336", "Shopping", "Copy a product link"),
  MoolAssistantAction("AI-ACT-337", "Shopping", "Share a product with someone"),
  MoolAssistantAction(
    "AI-ACT-338",
    "Shopping",
    "Find products in a particular Store",
  ),
  MoolAssistantAction(
    "AI-ACT-339",
    "Shopping",
    "Contact the supplier for this product",
  ),
  MoolAssistantAction(
    "AI-ACT-340",
    "Shopping",
    "Request purchase-finance assistance",
  ),
  MoolAssistantAction(
    "AI-ACT-341",
    "Shopping",
    "Ask someone for a delivery address",
  ),
  MoolAssistantAction(
    "AI-ACT-342",
    "Shopping",
    "Set the invoice recipient details",
  ),
  MoolAssistantAction(
    "AI-ACT-343",
    "Shopping",
    "Choose a supplied UPI payment QR",
  ),
  MoolAssistantAction(
    "AI-ACT-344",
    "Shopping",
    "Cancel an unpaid payment attempt",
  ),
  MoolAssistantAction(
    "AI-ACT-345",
    "Shopping",
    "Continue checkout for remaining suppliers",
  ),
  MoolAssistantAction(
    "AI-ACT-346",
    "Shopping",
    "Remove an unavailable checkout item",
  ),
  MoolAssistantAction("AI-ACT-347", "Shopping", "Remove a cart offer"),
  MoolAssistantAction(
    "AI-ACT-348",
    "Shopping",
    "Remove a retained supplier quote from this purchase",
  ),
  MoolAssistantAction(
    "AI-ACT-349",
    "Shopping",
    "Review a retained supplier quote for this purchase",
  ),
  MoolAssistantAction(
    "AI-ACT-350",
    "Shopping",
    "Prepare an existing supported purchase-order request",
  ),
  MoolAssistantAction(
    "AI-ACT-351",
    "Shopping",
    "Review a changed purchase-order revision",
  ),
  MoolAssistantAction(
    "AI-ACT-352",
    "Shopping",
    "Check a stale or changed commodity price",
  ),
  MoolAssistantAction("AI-ACT-353", "Chat", "Search within a conversation"),
  MoolAssistantAction(
    "AI-ACT-354",
    "Chat",
    "Find shared files, media or links",
  ),
  MoolAssistantAction("AI-ACT-355", "Chat", "Copy a message"),
  MoolAssistantAction("AI-ACT-356", "Chat", "Open a received attachment"),
  MoolAssistantAction("AI-ACT-357", "Chat", "Change my Chat availability"),
  MoolAssistantAction("AI-ACT-358", "Chat", "Hide or show message previews"),
  MoolAssistantAction("AI-ACT-359", "Chat", "Change suggested message prompts"),
  MoolAssistantAction(
    "AI-ACT-360",
    "Chat",
    "Change supported message review preferences",
  ),
  MoolAssistantAction(
    "AI-ACT-361",
    "Chat",
    "Change supported presence sharing",
  ),
  MoolAssistantAction("AI-ACT-362", "Chat", "Enable device Chat notifications"),
  MoolAssistantAction(
    "AI-ACT-363",
    "Chat",
    "Disable device Chat notifications",
  ),
  MoolAssistantAction("AI-ACT-364", "Social", "Open a post in full"),
  MoolAssistantAction(
    "AI-ACT-365",
    "Social",
    "Change the area used for public discovery",
  ),
  MoolAssistantAction(
    "AI-ACT-366",
    "Social",
    "Find something by scanning a code",
  ),
  MoolAssistantAction("AI-ACT-367", "Social", "Search by voice"),
  MoolAssistantAction(
    "AI-ACT-368",
    "Social",
    "Check my connected YouTube channel status",
  ),
  MoolAssistantAction(
    "AI-ACT-369",
    "Products",
    "Add or identify a product by barcode",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-370",
    "Products",
    "Edit a product's warranty details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-371",
    "Products",
    "Choose whether available quantity is public",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-372",
    "Products",
    "Find products needing price confirmation",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-373",
    "Products",
    "Check an interrupted product-media upload",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-374",
    "Products",
    "Check a variant publication attempt",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-375",
    "Purchases and supplier accounts",
    "Record a supplier GST credit note",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-376",
    "Purchases and supplier accounts",
    "Record a supplier commercial credit note",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-377",
    "Purchases and supplier accounts",
    "Recover an interrupted payment or credit allocation",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-378",
    "Purchases and supplier accounts",
    "Recover an interrupted supplier refund entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-379",
    "Purchases and supplier accounts",
    "Recover an interrupted supplier credit-note entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-380",
    "Purchases and supplier accounts",
    "Recover an interrupted supplier-return entry",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-381",
    "Purchases and supplier accounts",
    "Correct a saved opening-dues record",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-382",
    "Sales and customers",
    "Send a sales invoice in MoolSocial Chat",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-383",
    "Sales and customers",
    "Share a sales invoice on WhatsApp",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-384",
    "Sales and customers",
    "Print a sales invoice",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-385",
    "Sales and customers",
    "Scan products into a counter sale",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-386",
    "Sales and customers",
    "Recover an interrupted counter-sale draft",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-387",
    "Sales and customers",
    "View money activity for a period",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-388",
    "Sales and customers",
    "Report purchase-linked feedback",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-389",
    "Orders and fulfilment",
    "View the original documents linked to an order",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-390",
    "Orders and fulfilment",
    "Open an original document or its previous revision",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-391",
    "Orders and fulfilment",
    "Review an order amendment or cancellation document",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-392",
    "Orders and fulfilment",
    "View the warranty recorded for a purchase",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-393",
    "Orders and fulfilment",
    "View a purchase's serial or IMEI details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-394",
    "Orders and fulfilment",
    "Prepare serial or IMEI details for the buyer",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-395",
    "Orders and fulfilment",
    "Share purchase-linked device details with the buyer",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-396",
    "Orders and fulfilment",
    "Report a purchase-linked device mismatch",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-397",
    "Orders and fulfilment",
    "View buyer device-mismatch reports",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-398",
    "Orders and fulfilment",
    "Check whether device details were shared",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-399",
    "Orders and fulfilment",
    "Check a device-mismatch report's status",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-400",
    "Orders and fulfilment",
    "Open a linked after-sales case",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-401",
    "Stock and receiving",
    "Choose the receiving document type",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-402",
    "Stock and receiving",
    "Add a printed field from the original document",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-403",
    "Stock and receiving",
    "Add a printed tax-table row",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-404",
    "Stock and receiving",
    "Review or copy printed details",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-405",
    "Stock and receiving",
    "View the original scanned document",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-406",
    "Stock and receiving",
    "Review the detected document text",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-407",
    "Stock and receiving",
    "Print a stock statement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-408",
    "Stock and receiving",
    "Download a stock statement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-409",
    "Offers, finance and reports",
    "Print an account statement",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-410",
    "Offers, finance and reports",
    "Download a report or statement PDF",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-411",
    "Offers, finance and reports",
    "Open the detailed report behind a summary",
    store: true,
  ),
  MoolAssistantAction(
    "AI-ACT-412",
    "Offers, finance and reports",
    "Share my Store link",
    store: true,
  ),
  MoolAssistantAction('AI-ACT-413', 'Shopping', 'View my order invoice'),
  MoolAssistantAction('AI-ACT-414', 'Shopping', 'Download my order invoice'),
];

/// Presentation context, never a substitute for a domain permission check.
@immutable
class MoolAssistantContext {
  const MoolAssistantContext({
    required this.accountScope,
    required this.authenticationRevision,
    this.workspaceId,
    this.workspaceName,
    this.workspaceProfile,
    this.workspaceRevision,
    this.storeWorkspace = false,
    this.workspaceApproved = false,
  });

  final Object? accountScope;
  final int? authenticationRevision;
  final String? workspaceId;
  final String? workspaceName;
  final String? workspaceProfile;
  final int? workspaceRevision;
  final bool storeWorkspace;
  final bool workspaceApproved;

  bool get signedIn => accountScope != null && authenticationRevision != null;
  bool get inWorkspace =>
      signedIn &&
      workspaceApproved &&
      workspaceId?.isNotEmpty == true &&
      workspaceRevision != null;
  Object get binding => (
    accountScope,
    authenticationRevision,
    workspaceId,
    workspaceProfile,
    workspaceRevision,
    storeWorkspace,
    workspaceApproved,
  );

  MoolAssistantContext withWorkspace(MoolAssistantWorkspace? workspace) {
    final approved =
        signedIn &&
        workspace?.approved == true &&
        workspace?.approvalAccountScope == accountScope;
    return MoolAssistantContext(
      accountScope: accountScope,
      authenticationRevision: authenticationRevision,
      workspaceId: approved ? workspace?.id : null,
      workspaceName: approved ? workspace?.name : null,
      workspaceProfile: approved ? workspace?.profile : null,
      workspaceRevision: approved ? workspace?.revision : null,
      storeWorkspace: approved && workspace?.isStore == true,
      workspaceApproved: approved,
    );
  }
}

@immutable
class MoolAssistantWorkspace {
  const MoolAssistantWorkspace({
    required this.id,
    required this.name,
    required this.profile,
    required this.revision,
    this.isStore = false,
    this.approved = false,
    this.approvalAccountScope,
  });

  final String id;
  final String name;
  final String? profile;
  final int revision;
  final bool isStore;
  final bool approved;
  final Object? approvalAccountScope;
}

class MoolAssistantAttachment extends WorkPickedProof {
  const MoolAssistantAttachment({
    required super.fileName,
    required super.contentType,
    required super.bytes,
    super.recoveryPath,
    this.duration,
    this.source,
  });
  final Duration? duration;
  final WorkProofSource? source;
}

enum MoolAssistantDocumentProblem { unsupported, empty, tooLarge }

class MoolAssistantDocumentException implements Exception {
  const MoolAssistantDocumentException(this.problem);
  final MoolAssistantDocumentProblem problem;
  String get message => switch (problem) {
    MoolAssistantDocumentProblem.unsupported =>
      'Choose a PDF, text, DOCX, CSV or JSON file.',
    MoolAssistantDocumentProblem.empty => 'This file is empty. Choose another file.',
    MoolAssistantDocumentProblem.tooLarge => 'Choose a document up to 15 MB.',
  };
}

enum MoolAssistantAccess {
  checking,
  subscriptionRequired,
  purchasePending,
  active,
  expired,
  revoked,
  unavailable,
}

/// Supplied only by the verified subscription integration (THIN-B01).
/// An existing local subscription preference is not a source for this value.
@immutable
class MoolAssistantEntitlement {
  const MoolAssistantEntitlement({
    required this.accountScope,
    required this.access,
    required this.revision,
    this.validUntil,
  });

  final Object accountScope;
  final MoolAssistantAccess access;
  final String revision;
  final DateTime? validUntil;
}

abstract interface class MoolAssistantEntitlementSource implements Listenable {
  Future<MoolAssistantEntitlement> read(Object accountScope);
}

@immutable
class MoolAssistantAction {
  const MoolAssistantAction(
    this.id,
    this.group,
    this.label, {
    this.store = false,
  });
  final String id, group, label;
  final bool store;
  String get request => 'Help me with this task: $label.';
  bool get buyerMvpTask =>
      !store &&
      ((group == 'Shopping' && id != 'AI-ACT-036') ||
          const {
            'AI-ACT-187',
            'AI-ACT-188',
            'AI-ACT-189',
            'AI-ACT-190',
            'AI-ACT-191',
            'AI-ACT-192',
            'AI-ACT-193',
            'AI-ACT-194',
            'AI-ACT-195',
          }.contains(id));
}

@immutable
class MoolAssistantConversation {
  MoolAssistantConversation({
    required this.id,
    required this.binding,
    required this.title,
    required this.updatedAt,
    this.draft = '',
    this.language = 'Auto',
    List<(bool, String)> messages = const [],
    List<MoolAssistantAttachment> attachments = const [],
  }) : messages = List.unmodifiable(messages),
       attachments = List.unmodifiable(attachments);
  final String id, title, draft, language;
  final Object binding;
  final DateTime updatedAt;

  /// True denotes user text. History text never contains executable proposals.
  final List<(bool, String)> messages;
  final List<MoolAssistantAttachment> attachments;
}

@immutable
class MoolAssistantHistoryPage {
  MoolAssistantHistoryPage({
    required this.binding,
    required List<MoolAssistantConversation> items,
    this.nextCursor,
  }) : items = List.unmodifiable(items);
  final Object binding;
  final List<MoolAssistantConversation> items;
  final String? nextCursor;
}

/// Frontend boundary only. Production has no history receiver yet.
/// Implementations must authorise the current actor/context on every request,
/// persist only supplied private data, and deduplicate saves by draftKey.
abstract interface class MoolAssistantHistorySource {
  Future<MoolAssistantHistoryPage> list(
    MoolAssistantContext context, {
    String? cursor,
  });
  Future<MoolAssistantConversation> read(
    MoolAssistantContext context,
    String id,
  );
  Future<MoolAssistantConversation> saveDraft(
    MoolAssistantContext context, {
    required String draftKey,
    String? conversationId,
    required String text,
    required String language,
    required List<MoolAssistantAttachment> attachments,
  });
}

/// Per-item preparation state only; none of these values establishes a
/// purchase, payment, publication or other business result.
enum MoolAssistantPreparationState { ready, needsInput, unavailable }

@immutable
class MoolAssistantPreparationItem {
  const MoolAssistantPreparationItem({required this.id,required this.actionId,
    required this.title,required this.detail,required this.state,this.proposal});
  final String id,actionId,title,detail;
  final MoolAssistantPreparationState state;
  final MoolAssistantProposal? proposal;
}

/// An ephemeral, account/request-bound preparation response. Each ready item
/// still enters the existing single-proposal Review and original native form.
@immutable
class MoolAssistantPreparationBatch {
  MoolAssistantPreparationBatch({required this.id,required this.binding,
    required this.requestRevision,required this.entitlementRevision,
    required this.validUntil,required Iterable<MoolAssistantPreparationItem> items})
    :items=List.unmodifiable(items);
  final String id,entitlementRevision;
  final Object binding;
  final int requestRevision;
  final DateTime validUntil;
  final List<MoolAssistantPreparationItem> items;
}

/// Immutable frontend proposal data, never an instruction to post/save.
@immutable
class MoolAssistantProposal {
  MoolAssistantProposal({
    required this.id,
    required this.actionId,
    required this.binding,
    required this.requestRevision,
    required this.entitlementRevision,
    required this.sourceRevision,
    required this.validUntil,
    required this.title,
    required this.summary,
    this.entityId,
    required Map<String, Object?> fields,
  }) : fields = _freezeAssistantFields(fields);

  final String id,
      actionId,
      entitlementRevision,
      sourceRevision,
      title,
      summary;
  final Object binding;
  final int requestRevision;
  final DateTime validUntil;
  final String? entityId;
  final Map<String, Object?> fields;
}

Map<String, Object?> _freezeAssistantFields(Map<String, Object?> fields) {
  final visiting = Set<Object>.identity();
  Object? freeze(Object? value) {
    if (value == null || value is String || value is bool || value is int) {
      return value;
    }
    if (value is double && value.isFinite) return value;
    if (value is! Map && value is! List) {
      throw ArgumentError('Proposal fields must contain finite JSON values.');
    }
    if (!visiting.add(value)) {
      throw ArgumentError('Proposal fields cannot be cyclic.');
    }
    try {
      if (value is List) {
        return List<Object?>.unmodifiable(value.map(freeze));
      }
      final map = value as Map;
      if (map.keys.any((key) => key is! String)) {
        throw ArgumentError('Proposal field names must be strings.');
      }
      return Map<String, Object?>.unmodifiable({
        for (final key in map.keys) key as String: freeze(map[key]),
      });
    } finally {
      visiting.remove(value);
    }
  }

  return freeze(fields) as Map<String, Object?>;
}

/// Read from the original native owner immediately before review.
@immutable
class MoolAssistantNativeSnapshot {
  const MoolAssistantNativeSnapshot({
    required this.binding,
    required this.sourceRevision,
    required this.permitted,
    this.entityId,
  });
  final Object binding;
  final String sourceRevision;
  final bool permitted;
  final String? entityId;
}

/// These are presentation outcomes, not order/payment/publication outcomes.
enum MoolAssistantReviewResult {
  opened,
  returnToOwner,
  cancelled,
  unavailable,
  stale,
}

/// Each capability reuses one original frontend form/read owner.
/// snapshot and validateFields must not post. openReview must recheck isCurrent
/// after any await and before navigation; the original form owns final consent.
abstract interface class MoolAssistantNativeAdapter {
  String get actionId;
  Set<String> get allowedFields;
  String? validateFields(Map<String, Object?> fields);
  Future<MoolAssistantNativeSnapshot?> snapshot(
    MoolAssistantContext context,
    String? entityId,
  );
  Future<MoolAssistantReviewResult> openReview(
    MoolAssistantProposal proposal,
    bool Function() isCurrent,
  );
}

/// Additive FE-HANDOFF01 signal. Notification rechecks authority; it grants none.
abstract interface class MoolAssistantOwnerAwareNativeAdapter implements MoolAssistantNativeAdapter {
  Future<MoolAssistantReviewResult> openOwnedReview(MoolAssistantProposal proposal,
    {required bool Function() isCurrent, required Listenable ownerChanges});
}

/// Metadata only: safe to reference a selected file without serializing bytes/paths.
@immutable
class MoolAssistantDocumentReference {
  const MoolAssistantDocumentReference({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.byteLength,
    required this.source,
  });
  final String id, fileName, contentType;
  final int byteLength;
  final WorkProofSource source;
  Map<String, Object?> toJson() => {
    'attachmentRef': id,
    'fileName': fileName,
    'contentType': contentType,
    'byteLength': byteLength,
    'source': source.name,
  };
}

/// In-process user-selected input. Only the controller can mint this value.
/// Native owners must still validate bytes and scope before retaining a copy.
@immutable
class MoolAssistantSelectedDocument {
  const MoolAssistantSelectedDocument._({
    required this.reference,
    required this.proof,
    required this.sourceDigest,
    required this.ownerChanges,
    required Object binding,
    required int epoch,
  }) : _binding = binding,
       _epoch = epoch;
  final MoolAssistantDocumentReference reference;
  final WorkPickedProof proof; // Read-only copied bytes; no recovery path.
  final String sourceDigest;
  // Notification only. Native current() remains the authority for every effect.
  final Listenable ownerChanges;
  final Object _binding;
  final int _epoch;
}

/// Optional additive extension; ordinary native adapters remain unchanged.
/// The resolver is available only during the current explicit Review operation.
abstract interface class MoolAssistantSelectedDocumentAdapter
    implements MoolAssistantNativeAdapter {
  Future<MoolAssistantReviewResult> openSelectedDocumentReview(
    MoolAssistantProposal proposal,
    bool Function() isCurrent,
    MoolAssistantSelectedDocument? Function(String reference) resolve,
  );
}

Map<String, MoolAssistantNativeAdapter> _assistantNativeRegistry(
  Iterable<MoolAssistantNativeAdapter> adapters,
) {
  final registry = <String, MoolAssistantNativeAdapter>{};
  for (final adapter in adapters) {
    final known = moolAssistantActions.any(
      (action) =>
          action.id == adapter.actionId &&
          (action.store || action.buyerMvpTask),
    );
    if (!known || registry.containsKey(adapter.actionId)) {
      throw ArgumentError('Native AI capability must be unique and in scope.');
    }
    registry[adapter.actionId] = adapter;
  }
  return Map.unmodifiable(registry);
}

/// Ephemeral composer state. It does not persist text, post a domain command,
/// call a model, activate a subscription or resolve arbitrary app routes.
class MoolAssistantController extends ChangeNotifier {
  MoolAssistantController({
    required MoolAssistantContext Function() currentContext,
    required this.contextChanges,
    this.entitlements,
    this.attachments,
    this.mediaPicker,
    this.voiceRecorder,
    this.historySource,
    Iterable<MoolAssistantNativeAdapter> nativeAdapters = const [],
    DateTime Function()? clock,
  }) : _nativeAdapters = _assistantNativeRegistry(nativeAdapters),
       _currentContext = currentContext,
       _clock = clock ?? DateTime.now,
       context = currentContext() {
    contextChanges.addListener(synchronize);
    entitlements?.addListener(_sourceChanged);
    unawaited(refreshAccess());
  }

  final MoolAssistantContext Function() _currentContext;
  final Listenable contextChanges;
  final MoolAssistantEntitlementSource? entitlements;
  final WorkProofPicker? attachments;
  final ChatAttachmentPicker? mediaPicker;
  final ChatVoiceRecorder? voiceRecorder;
  final MoolAssistantHistorySource? historySource;
  final DateTime Function() _clock;
  final Map<String, MoolAssistantNativeAdapter> _nativeAdapters;
  int _requestRevision = 0, _reviewAttempt = 0;
  int? _nativeReviewAttempt;
  Completer<MoolAssistantNativeSnapshot?>? _snapshotRetirement;
  MoolAssistantProposal? _proposal;
  MoolAssistantPreparationBatch? _preparationBatch;
  Timer? _preparationExpiry;
  final Set<String> _selectedPreparationItems={};
  final Set<String> _receivedPreparationIds={};
  MoolAssistantPreparationBatch? get preparationBatch =>
      _preparationBatchCurrent ? _preparationBatch:null;
  bool preparationItemSelected(String id)=>_selectedPreparationItems.contains(id);
  bool get _preparationBatchCurrent {
    final batch=_preparationBatch;
    return batch!=null && !_disposed && _foreground && paidAccessCurrent &&
      batch.binding==context.binding && batch.requestRevision==_requestRevision &&
      batch.entitlementRevision==_entitlement?.revision && batch.validUntil.isAfter(_clock());
  }
  final Set<String> _receivedProposalIds = {};
  MoolAssistantProposal? get proposal => _proposal;
  int get requestRevision => _requestRevision;
  DateTime get presentationTime => _clock();
  String? get entitlementRevision => _entitlement?.revision;
  bool reviewBusy = false;
  String? proposalNotice;
  MoolAssistantContext context;
  MoolAssistantAccess access = MoolAssistantAccess.unavailable;
  MoolAssistantEntitlement? _entitlement;
  Timer? _expiry;
  bool _disposed = false;
  bool _foreground = true;

  /// Backgrounding retires consent to open a proposal, not the user's input.
  void setForeground(bool value) {
    if (_disposed || _foreground == value) return;
    _foreground = value;
    if (!value && (_proposal != null || _preparationBatch != null)) {
      _retireProposal(requestChanged: false);
      proposalNotice = 'Review paused. Please ask again when you return.';
    }
    notifyListeners();
  }

  int _readAttempt = 0;
  int _epoch = 0;
  String _draft = '';
  final List<MoolAssistantAttachment> _selected = [];
  final _selectedDocuments =
      <MoolAssistantAttachment, MoolAssistantSelectedDocument>{};
  static const _documentTypes = {
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/json',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  MoolAssistantSelectedDocument _selectedDocument(
    MoolAssistantAttachment item,
  ) => _selectedDocuments.putIfAbsent(item, () {
    final bytes = Uint8List.fromList(item.bytes).asUnmodifiableView();
    final random = math.Random.secure();
    final id =
        'att-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    return MoolAssistantSelectedDocument._(
      reference: MoolAssistantDocumentReference(
        id: id,
        fileName: item.fileName,
        contentType: item.contentType,
        byteLength: bytes.length,
        source: item.source!,
      ),
      proof: WorkPickedProof(
        fileName: item.fileName,
        contentType: item.contentType,
        bytes: bytes,
      ),
      sourceDigest: crypto.sha256.convert(bytes).toString(),
      ownerChanges: this,
      binding: context.binding,
      epoch: _epoch,
    );
  });

  List<MoolAssistantDocumentReference> get selectedDocumentReferences =>
      List.unmodifiable([
        for (final item in _selected)
          if (item.source != null && _documentTypes.contains(item.contentType))
            _selectedDocument(item).reference,
      ]);

  MoolAssistantSelectedDocument? _resolveSelectedDocument(
    String reference,
    MoolAssistantProposal proposal,
  ) {
    synchronize();
    if (_disposed ||
        !_proposalCurrent(proposal) ||
        !paidAccessCurrent ||
        proposal.fields['attachmentRef'] != reference ||
        proposal.requestRevision != _requestRevision ||
        proposal.binding != context.binding)
      return null;
    for (final item in _selected) {
      final document = _selectedDocuments[item];
      if (document != null &&
          document.reference.id == reference &&
          document._binding == context.binding &&
          document._epoch == _epoch)
        return document;
    }
    return null;
  }

  List<MoolAssistantAttachment> get selectedAttachments =>
      List.unmodifiable(_selected);
  MoolAssistantAttachment? get attachment => _selected.firstOrNull;
  String language = 'Auto';
  String? taskId;
  bool recording = false;
  bool voiceBusy = false;
  int _voiceAttempt = 0;
  DateTime? _voiceStarted;
  Timer? _voiceTimer;
  Duration get voiceDuration => _voiceStarted == null
      ? Duration.zero
      : _clock().difference(_voiceStarted!);
  bool pickingAttachment = false;
  String? notice;

  final List<MoolAssistantConversation> _history = [];
  List<MoolAssistantConversation> get history => List.unmodifiable(_history);
  List<(bool, String)> messages = const [];
  String? conversationId, historyCursor, historyNotice;
  String? conversationTitle;
  bool historyLoading = false, historyBusy = false;
  int _historyRead = 0, _historyWrite = 0, _conversationGeneration = 0;
  final String _draftSession = DateTime.now().microsecondsSinceEpoch.toString();
  bool get hasInput => _draft.trim().isNotEmpty || _selected.isNotEmpty;
  bool get canChangeConversation =>
      !historyBusy &&
      !reviewBusy &&
      !recording &&
      !voiceBusy &&
      !pickingAttachment;

  void _retireProposal({bool requestChanged = true,bool preservePreparationBatch = false}) {
    if(!preservePreparationBatch){
      _preparationExpiry?.cancel();_preparationExpiry=null;
      _preparationBatch=null;_selectedPreparationItems.clear();
    }
    if (requestChanged) {
      _requestRevision++;
      _receivedProposalIds.clear();
      _receivedPreparationIds.clear();
    }
    _proposal = null;
    proposalNotice = null;
    // Read-only lookups may be abandoned immediately. Once the native owner
    // has been entered, keep its ownership until that original Future ends.
    if (reviewBusy && _nativeReviewAttempt != _reviewAttempt) {
      _reviewAttempt++;
      reviewBusy = false;
      final retired = _snapshotRetirement;
      _snapshotRetirement = null;
      if (retired != null && !retired.isCompleted) retired.complete(null);
    }
  }

  bool _proposalCurrent(MoolAssistantProposal value) =>
      !_disposed &&
      _foreground &&
      !historyBusy &&
      !recording &&
      !voiceBusy &&
      !pickingAttachment &&
      identical(_proposal, value) &&
      paidAccessCurrent &&
      value.binding == context.binding &&
      value.requestRevision == _requestRevision &&
      value.entitlementRevision == _entitlement?.revision &&
      value.validUntil.isAfter(_clock());

  String? _proposalValidation(MoolAssistantProposal value) {
    final adapter = _nativeAdapters[value.actionId];
    if (adapter == null ||
        !actions().any((action) => action.id == value.actionId)) {
      return 'Review is unavailable for this task.';
    }
    if (!_foreground ||
        !paidAccessCurrent ||
        value.binding != context.binding ||
        value.requestRevision != _requestRevision ||
        value.entitlementRevision != _entitlement?.revision ||
        !value.validUntil.isAfter(_clock()) ||
        value.id.trim().isEmpty ||
        value.title.trim().isEmpty ||
        value.summary.trim().isEmpty ||
        value.sourceRevision.trim().isEmpty ||
        (value.entityId != null && value.entityId!.trim().isEmpty)) {
      return 'This suggestion is no longer current. Please ask again.';
    }
    if (!value.fields.keys.every(adapter.allowedFields.contains)) {
      return 'Some suggested details cannot be used for this task.';
    }
    try {
      return adapter.validateFields(value.fields);
    } on Object {
      return 'The suggested details could not be checked.';
    }
  }

  /// Accepts typed preparation, never an execution plan or an effect result.
  /// Invalid ready items reject the whole envelope; they are not downgraded
  /// into a fabricated success or silently omitted from the response.
  bool receivePreparationBatch(MoolAssistantPreparationBatch batch) {
    if(_disposed)return false;synchronize();
    if(!hasInput || !canChangeConversation || _proposal!=null || _preparationBatch!=null ||
       !_foreground || !paidAccessCurrent || batch.id.trim().isEmpty || _receivedPreparationIds.contains(batch.id) ||
       batch.binding!=context.binding || batch.requestRevision!=_requestRevision ||
       batch.entitlementRevision!=_entitlement?.revision || !batch.validUntil.isAfter(_clock()) ||
       batch.items.isEmpty || batch.items.map((v)=>v.id).toSet().length!=batch.items.length)return false;
    final actionsById={for(final action in actions())action.id:action};
    final proposalIds=<String>{};
    for(final item in batch.items){
      final proposal=item.proposal;
      if(item.id.trim().isEmpty || item.title.trim().isEmpty || item.detail.trim().isEmpty ||
         !actionsById.containsKey(item.actionId))return false;
      if(item.state==MoolAssistantPreparationState.ready){
        if(proposal==null || proposal.actionId!=item.actionId ||
           proposal.binding!=batch.binding || proposal.requestRevision!=batch.requestRevision ||
           proposal.entitlementRevision!=batch.entitlementRevision ||
           proposal.validUntil.isBefore(batch.validUntil) ||
           !proposalIds.add(proposal.id) || _receivedProposalIds.contains(proposal.id) ||
           _proposalValidation(proposal)!=null)return false;
      }else if(proposal!=null){return false;}
    }
    _preparationBatch=batch;_receivedPreparationIds.add(batch.id);_selectedPreparationItems.clear();
    _preparationExpiry=Timer(batch.validUntil.difference(_clock()),(){
      if(!_disposed && identical(_preparationBatch,batch))cancelProposal();
    });
    notifyListeners();return true;
  }

  bool choosePreparationItem(String id){
    if(_disposed)return false;synchronize();
    if(!_preparationBatchCurrent || !canChangeConversation || _proposal!=null ||
       _selectedPreparationItems.contains(id))return false;
    final matches=_preparationBatch!.items.where((item)=>item.id==id);
    if(matches.length!=1 || matches.single.state!=MoolAssistantPreparationState.ready)return false;
    final value=matches.single.proposal;
    if(value==null || !receiveProposal(value))return false;
    _selectedPreparationItems.add(id);notifyListeners();return true;
  }

  bool receiveProposal(MoolAssistantProposal value) {
    if (_disposed) return false;
    synchronize();
    if (!hasInput ||
        !canChangeConversation ||
        _proposal != null ||
        _receivedProposalIds.contains(value.id)) {
      return false;
    }
    final error = _proposalValidation(value);
    if (error != null) {
      proposalNotice = error;
      notifyListeners();
      return false;
    }
    _proposal = value;
    _receivedProposalIds.add(value.id);
    proposalNotice = null;
    notifyListeners();
    return true;
  }

  void cancelProposal() {
    if (_disposed) return;
    _retireProposal(requestChanged: false);
    notifyListeners();
  }

  Future<MoolAssistantReviewResult> reviewProposal() async {
    if (_disposed || reviewBusy) return MoolAssistantReviewResult.unavailable;
    synchronize();
    final value = _proposal;
    if (value == null) return MoolAssistantReviewResult.unavailable;
    if (!_proposalCurrent(value) || _proposalValidation(value) != null) {
      _retireProposal(requestChanged: false);
      proposalNotice = 'This suggestion changed. Please ask again.';
      notifyListeners();
      return MoolAssistantReviewResult.stale;
    }
    final adapter = _nativeAdapters[value.actionId]!;
    final attempt = ++_reviewAttempt;
    final retired = Completer<MoolAssistantNativeSnapshot?>();
    _snapshotRetirement = retired;
    _nativeReviewAttempt = null;
    reviewBusy = true;
    proposalNotice = null;
    notifyListeners();
    var nativeReviewStarted = false;
    try {
      if (attempt != _reviewAttempt || !_proposalCurrent(value)) {
        return MoolAssistantReviewResult.stale;
      }
      final native = await Future.any<MoolAssistantNativeSnapshot?>([
        adapter.snapshot(context, value.entityId),
        retired.future,
      ]);
      if (identical(_snapshotRetirement, retired)) _snapshotRetirement = null;
      if (_disposed || attempt != _reviewAttempt)
        return MoolAssistantReviewResult.stale;
      synchronize();
      if (!_proposalCurrent(value)) return MoolAssistantReviewResult.stale;
      if (native == null) {
        proposalNotice = 'The original details are unavailable right now.';
        return MoolAssistantReviewResult.unavailable;
      }
      if (!native.permitted ||
          native.binding != value.binding ||
          native.entityId != value.entityId ||
          native.sourceRevision.isEmpty ||
          native.sourceRevision != value.sourceRevision) {
        _retireProposal(requestChanged: false);
        proposalNotice =
            'The original details changed. Please review a fresh suggestion.';
        return MoolAssistantReviewResult.stale;
      }
      nativeReviewStarted = true;
      _nativeReviewAttempt = attempt;
      bool currentReview() =>
          attempt == _reviewAttempt && _proposalCurrent(value);
      final result = adapter is MoolAssistantSelectedDocumentAdapter
          ? await adapter.openSelectedDocumentReview(
              value,
              currentReview,
              (reference) => currentReview()
                  ? _resolveSelectedDocument(reference, value)
                  : null,
            )
          : adapter is MoolAssistantOwnerAwareNativeAdapter
          ? await adapter.openOwnedReview(value, isCurrent: currentReview, ownerChanges: this)
          : await adapter.openReview(value, currentReview);
      if (_disposed) return MoolAssistantReviewResult.stale;
      synchronize();
      if (!_proposalCurrent(value)) return MoolAssistantReviewResult.stale;
      _retireProposal(requestChanged: false,preservePreparationBatch:true);
      proposalNotice = switch (result) {
        MoolAssistantReviewResult.opened => null,
        MoolAssistantReviewResult.returnToOwner => 'Your review is ready.',
        MoolAssistantReviewResult.cancelled => null,
        MoolAssistantReviewResult.unavailable =>
          'Review is unavailable right now.',
        MoolAssistantReviewResult.stale =>
          'The original details changed. Please ask again.',
      };
      return result;
    } on Object {
      if (!_disposed && attempt == _reviewAttempt && _proposalCurrent(value)) {
        if (nativeReviewStarted) {
          _retireProposal(requestChanged: false);
          proposalNotice =
              'Review status is unclear. Check the original screen before trying again.';
        } else {
          proposalNotice = 'Unable to open review. Your request is still here.';
        }
      }
      return MoolAssistantReviewResult.unavailable;
    } finally {
      if (identical(_snapshotRetirement, retired)) _snapshotRetirement = null;
      if (!_disposed) {
        if (attempt == _reviewAttempt) {
          reviewBusy = false;
          _nativeReviewAttempt = null;
        }
        // An obsolete read can notify current state, but cannot unlock or
        // replace the newer attempt that now owns the composer.
        notifyListeners();
      }
    }
  }

  List<MoolAssistantAction> actions([String query = '']) {
    final text = query.trim().toLowerCase();
    return moolAssistantActions
        .where(
          (a) =>
              (context.inWorkspace
                  ? context.storeWorkspace && a.store
                  : a.buyerMvpTask && a.group == 'Shopping') &&
              (text.isEmpty ||
                  '${a.label} ${a.group}'.toLowerCase().contains(text)),
        )
        .toList(growable: false);
  }

  bool chooseAction(String id, {bool replaceDraft = false}) {
    if (_disposed) return false;
    synchronize();
    final matches = actions().where((a) => a.id == id);
    if (matches.length != 1 || !canChangeConversation) return false;
    final action = matches.single;
    if (_draft.trim().isNotEmpty && _draft != action.request && !replaceDraft) {
      return false;
    }
    chooseTask(action.store ? 'store.${action.id}' : action.id, action.request);
    return true;
  }

  Future<void> loadHistory({bool more = false}) async {
    if (_disposed) return;
    synchronize();
    if (historyLoading) return;
    if (historySource == null || !context.signedIn) {
      historyNotice = 'Chat history is unavailable right now.';
      notifyListeners();
      return;
    }
    final epoch = _epoch, attempt = ++_historyRead, binding = context.binding;
    final cursor = more ? historyCursor : null;
    if (more && cursor == null) return;
    historyLoading = true;
    historyNotice = null;
    notifyListeners();
    try {
      final page = await historySource!.list(context, cursor: cursor);
      if (_disposed) return;
      synchronize();
      if (epoch != _epoch ||
          attempt != _historyRead ||
          binding != context.binding) {
        return;
      }
      if (page.binding != binding ||
          page.items.any((i) => i.binding != binding || i.id.isEmpty) ||
          page.items.map((i) => i.id).toSet().length != page.items.length ||
          (page.nextCursor != null &&
              (page.nextCursor!.isEmpty || page.nextCursor == cursor))) {
        throw StateError('History scope/page mismatch');
      }
      final earlier = more
          ? List<MoolAssistantConversation>.of(_history)
          : <MoolAssistantConversation>[];
      for (final item in page.items) {
        earlier.removeWhere((i) => i.id == item.id);
        earlier.add(item);
      }
      earlier.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _history
        ..clear()
        ..addAll(earlier);
      historyCursor = page.nextCursor;
    } on Object {
      if (!_disposed && epoch == _epoch) {
        historyNotice = 'Could not load chat history. Try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch && attempt == _historyRead) {
        historyLoading = false;
        notifyListeners();
      }
    }
  }

  /// Saving must be acknowledged before the current draft may be retired.
  Future<bool> changeConversation({String? id}) async {
    if (_disposed) return false;
    synchronize();
    if (!canChangeConversation) return false;
    if (id != null && id == conversationId) return true;
    if (historySource == null && (id != null || hasInput)) {
      notice = 'Chat history is unavailable. Your current draft is unchanged.';
      notifyListeners();
      return false;
    }
    if (id != null && !_history.any((i) => i.id == id)) return false;
    final epoch = _epoch, binding = context.binding, attempt = ++_historyWrite;
    final text = _draft,
        selected = List<MoolAssistantAttachment>.of(_selected),
        lang = language;
    bool current() =>
        !_disposed &&
        epoch == _epoch &&
        binding == _currentContext().binding &&
        text == _draft &&
        lang == language &&
        listEquals(selected, _selected);
    historyBusy = true;
    notice = null;
    notifyListeners();
    try {
      if (hasInput) {
        if (!context.signedIn) throw StateError('Unauthenticated draft');
        final saved = await historySource!.saveDraft(
          context,
          draftKey:
              '$_draftSession:$_conversationGeneration:${Object.hash(text, lang, Object.hashAll(selected))}',
          conversationId: conversationId,
          text: text,
          language: lang,
          attachments: List.unmodifiable(selected),
        );
        if (!current()) return false;
        if (saved.binding != binding ||
            saved.id.isEmpty ||
            (conversationId != null && saved.id != conversationId) ||
            saved.draft != text ||
            saved.language != lang ||
            saved.attachments.length != selected.length ||
            !selected.asMap().entries.every((entry) {
              final original = entry.value, copy = saved.attachments[entry.key];
              return original.fileName == copy.fileName &&
                  original.contentType == copy.contentType &&
                  original.duration == copy.duration &&
                  (original.source == null || original.source == copy.source) &&
                  listEquals(original.bytes, copy.bytes);
            })) {
          throw StateError('Draft acknowledgement mismatch');
        }
      }
      MoolAssistantConversation? restored;
      if (id != null) {
        restored = await historySource!.read(context, id);
        if (!current()) return false;
        if (restored.binding != binding ||
            restored.id != id ||
            restored.language.trim().isEmpty ||
            restored.attachments.length > 10 ||
            restored.attachments.fold<int>(0, (n, a) => n + a.bytes.length) >
                32 * 1024 * 1024) {
          throw StateError('Conversation scope mismatch');
        }
      }
      if (!current()) return false;
      _retirePrivateInput();
      _conversationGeneration++;
      conversationId = restored?.id;
      conversationTitle = restored?.title;
      messages = restored?.messages ?? const [];
      _retireProposal();
      _draft = restored?.draft ?? '';
      language = restored?.language ?? 'Auto';
      _selected.addAll(restored?.attachments ?? const []);
      notifyListeners();
      return true;
    } on Object {
      if (current()) {
        notice = 'Could not switch chats. Your current draft is unchanged.';
      }
      return false;
    } finally {
      if (!_disposed && attempt == _historyWrite) {
        historyBusy = false;
        notifyListeners();
      }
    }
  }

  int get epoch => _epoch;

  /// Explicit user discard; never removes saved conversations or replays work.
  bool discardDraft() {
    if (_disposed || historyBusy) return false;
    _retirePrivateInput();
    _conversationGeneration++;
    notifyListeners();
    return true;
  }

  String get draft => _draft;
  bool get hasSubscriptionService => entitlements != null;

  bool get paidAccessCurrent =>
      !_disposed &&
      context.signedIn &&
      context.binding == _currentContext().binding &&
      access == MoolAssistantAccess.active &&
      _entitlement?.accountScope == context.accountScope &&
      _entitlement!.revision.isNotEmpty &&
      _entitlement!.validUntil != null &&
      _entitlement!.validUntil!.isAfter(_clock());

  bool get canAttach =>
      paidAccessCurrent &&
      (attachments != null || mediaPicker != null) &&
      !recording &&
      !voiceBusy;

  void chooseLanguage(String value) {
    if (_disposed) return;
    synchronize();
    final name = value.trim();
    if (name.isEmpty || name.length > 80) return;
    if (language != name) _retireProposal();
    language = name;
    notifyListeners();
  }

  void chooseTask(String id, String prompt) {
    synchronize();
    if (id.startsWith('store.') && !context.storeWorkspace) return;
    setDraft(prompt);
    taskId = id;
    notifyListeners();
  }

  void showInputUnavailable() {
    if (_disposed) return;
    notice = 'AI input is unavailable right now. You can type your request.';
    notifyListeners();
  }

  void setDraft(String value) {
    if (_disposed) return;
    synchronize();
    if (_draft != value) _retireProposal();
    taskId = null;
    _draft = value;
    notice = null;
    notifyListeners();
  }

  void _retirePrivateInput() {
    _retireProposal();
    _epoch++;
    _historyRead++;
    _historyWrite++;
    historyLoading = false;
    historyBusy = false;
    historyCursor = null;
    historyNotice = null;
    _history.clear();
    conversationId = null;
    conversationTitle = null;
    messages = const [];
    _draft = '';
    _selected.clear();
    _selectedDocuments.clear();
    language = 'Auto';
    taskId = null;
    _retireVoice();
    pickingAttachment = false;
    notice = null;
  }

  void synchronize() {
    if (_disposed) return;
    final next = _currentContext();
    if (next.binding != context.binding) {
      context = next;
      _retirePrivateInput();
      unawaited(refreshAccess());
    } else if (access == MoolAssistantAccess.active && !paidAccessCurrent) {
      _retirePrivateInput();
      _entitlement = null;
      access = MoolAssistantAccess.expired;
      notifyListeners();
    }
  }

  void _sourceChanged() {
    if (_disposed) return;
    _retirePrivateInput();
    unawaited(refreshAccess());
  }

  Future<void> refreshAccess() async {
    if (_disposed) return;
    if (_entitlement != null) _retirePrivateInput();
    final attempt = ++_readAttempt;
    final binding = context.binding;
    final account = context.accountScope;
    _expiry?.cancel();
    _entitlement = null;
    access = context.signedIn && entitlements != null
        ? MoolAssistantAccess.checking
        : MoolAssistantAccess.unavailable;
    notifyListeners();
    if (!context.signedIn || entitlements == null || account == null) return;
    try {
      final result = await entitlements!.read(account);
      if (_disposed || attempt != _readAttempt) return;
      if (binding != _currentContext().binding) {
        synchronize();
        return;
      }
      if (result.accountScope != account || result.revision.isEmpty) {
        access = MoolAssistantAccess.unavailable;
      } else if (result.access == MoolAssistantAccess.active &&
          (result.validUntil == null ||
              !result.validUntil!.isAfter(_clock()))) {
        access = MoolAssistantAccess.expired;
      } else {
        _entitlement = result;
        access = result.access;
        if (access == MoolAssistantAccess.active) {
          _expiry = Timer(result.validUntil!.difference(_clock()), synchronize);
        }
      }
    } on Object {
      if (_disposed || attempt != _readAttempt) return;
      access = MoolAssistantAccess.unavailable;
    }
    if (!_disposed && attempt == _readAttempt) notifyListeners();
  }

  Future<void> pickAttachment(WorkProofSource source) async {
    if (attachments == null) {
      showInputUnavailable();
      return;
    }
    await _pick(() => attachments!.pick(source), source: source);
  }

  Future<void> pickMedia(ChatAttachmentKind kind) async {
    if (kind != ChatAttachmentKind.document &&
        kind != ChatAttachmentKind.video) {
      return;
    }
    if (mediaPicker == null) {
      showInputUnavailable();
      return;
    }
    await _pick(() async {
      final selected = await mediaPicker!.pick(kind);
      return selected == null
          ? null
          : MoolAssistantAttachment(
              fileName: selected.name,
              contentType: selected.contentType,
              bytes: selected.bytes,
              source: kind == ChatAttachmentKind.document
                  ? WorkProofSource.upload
                  : null,
            );
    });
  }

  Future<void> _pick(
    Future<WorkPickedProof?> Function() pick, {
    WorkProofSource? source,
  }) async {
    synchronize();
    if (!canAttach) {
      showInputUnavailable();
      return;
    }
    if (pickingAttachment) return;
    final binding = context.binding;
    final epoch = _epoch;
    pickingAttachment = true;
    notice = null;
    notifyListeners();
    try {
      final picked = await pick();
      if (_disposed) return;
      synchronize();
      if (!paidAccessCurrent || binding != context.binding || epoch != _epoch) {
        return;
      }
      if (picked != null) {
        _addAttachment(
          MoolAssistantAttachment(
            fileName: picked.fileName,
            contentType: picked.contentType,
            bytes: picked.bytes,
            recoveryPath: picked.recoveryPath,
            source:
                source ??
                (picked is MoolAssistantAttachment ? picked.source : null),
          ),
        );
      }
    } on MoolAssistantDocumentException catch (error) {
      if (!_disposed && epoch == _epoch && paidAccessCurrent) {
        notice = error.message;
      }
    } on Object {
      if (!_disposed && epoch == _epoch && paidAccessCurrent) {
        notice = 'Unable to open the attachment. Please try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        pickingAttachment = false;
        notifyListeners();
      }
    }
  }

  void removeAttachment() {
    if (_selected.isNotEmpty) _retireProposal();
    _selected.clear();
    _selectedDocuments.clear();
    if (!_disposed) notifyListeners();
  }

  void removeSelectedAttachment(int index) {
    if (_disposed || index < 0 || index >= _selected.length) return;
    _retireProposal();
    final removed = _selected.removeAt(index);
    _selectedDocuments.remove(removed);
    notifyListeners();
  }

  void _addAttachment(MoolAssistantAttachment item) {
    // Client memory bounds, not a promise of server upload limits.
    if (_selected.length >= 10 ||
        _selected.fold<int>(item.bytes.length, (n, a) => n + a.bytes.length) >
            32 * 1024 * 1024) {
      notice =
          'These attachments are too large for one request. Remove a file or choose a smaller copy.';
      return;
    }
    _retireProposal();
    _selected.add(
      MoolAssistantAttachment(
        fileName: item.fileName,
        contentType: item.contentType,
        bytes: Uint8List.fromList(item.bytes).asUnmodifiableView(),
        recoveryPath: item.recoveryPath,
        duration: item.duration,
        source: item.source,
      ),
    );
  }

  Future<void> toggleVoice() async {
    synchronize();
    if (!paidAccessCurrent || voiceRecorder == null) {
      showInputUnavailable();
      return;
    }
    if (voiceBusy || pickingAttachment) return;
    final attempt = ++_voiceAttempt, epoch = _epoch;
    voiceBusy = true;
    notice = null;
    notifyListeners();
    try {
      if (recording) {
        final clip = await voiceRecorder!.stop();
        if (!_disposed) synchronize();
        recording = false;
        _voiceTimer?.cancel();
        if (!_disposed &&
            attempt == _voiceAttempt &&
            epoch == _epoch &&
            paidAccessCurrent) {
          _addAttachment(
            MoolAssistantAttachment(
              fileName: clip.name,
              contentType: clip.contentType,
              bytes: clip.bytes,
              duration: clip.duration,
            ),
          );
        }
      } else {
        await voiceRecorder!.start();
        if (!_disposed) synchronize();
        if (_disposed ||
            attempt != _voiceAttempt ||
            epoch != _epoch ||
            !paidAccessCurrent) {
          await _cancelNativeVoice();
          return;
        }
        recording = true;
        _voiceStarted = _clock();
        _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          synchronize();
          if (!_disposed && recording) notifyListeners();
        });
      }
    } on Object {
      recording = false;
      _voiceTimer?.cancel();
      await _cancelNativeVoice();
      if (!_disposed && attempt == _voiceAttempt && epoch == _epoch) {
        notice =
            'Voice recording was not completed. Check microphone access or type your request.';
      }
    } finally {
      voiceBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _cancelNativeVoice() async {
    try {
      await voiceRecorder?.cancel();
    } on Object {
      /* No clip is accepted. */
    }
  }

  void _retireVoice() {
    _voiceAttempt++;
    final active = recording || voiceBusy;
    recording = false;
    _voiceStarted = null;
    _voiceTimer?.cancel();
    if (active) unawaited(_cancelNativeVoice());
  }

  void cancelVoice() {
    _retireVoice();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _retireProposal(requestChanged: false);
    _receivedProposalIds.clear();
    _disposed = true;
    _readAttempt++;
    _expiry?.cancel();
    contextChanges.removeListener(synchronize);
    entitlements?.removeListener(_sourceChanged);
    _draft = '';
    _selected.clear();
    _selectedDocuments.clear();
    _retireVoice();
    voiceRecorder?.dispose();
    // Native selected-input owners can outlive the composer route. Publish
    // authoritative retirement before ChangeNotifier removes their listeners.
    notifyListeners();
    super.dispose();
  }
}
