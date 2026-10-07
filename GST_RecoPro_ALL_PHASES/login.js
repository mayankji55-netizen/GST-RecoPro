const form = document.getElementById("loginForm");
const password = document.getElementById("password");
const toggle = document.getElementById("togglePassword");
const message = document.getElementById("message");

toggle.addEventListener("click", () => {
  const visible = password.type === "text";
  password.type = visible ? "password" : "text";
  toggle.textContent = visible ? "Show" : "Hide";
  toggle.setAttribute("aria-label", visible ? "Show password" : "Hide password");
});

form.addEventListener("submit", (e) => {
  e.preventDefault();
  message.textContent = "";
  const userId = document.getElementById("userId").value.trim();
  const pass = password.value;

  if (!userId || !pass) {
    message.textContent = "Please enter User ID and Password.";
    return;
  }

  // Design-only page:
  // Connect the existing authentication logic here later.
  message.textContent = "Login connection will be linked to the existing authentication module.";
});
