const openPost = document.querySelector("#open-moolsocial-post");

if (openPost instanceof HTMLAnchorElement) {
  const target = new URL("/app/social", window.location.origin);
  const item = new URLSearchParams(window.location.search).get("item");
  target.searchParams.set("sub", "feed");
  if (item && item.trim()) target.searchParams.set("item", item.trim());
  openPost.href = target.toString();
}
