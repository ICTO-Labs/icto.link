import { backend } from "../../declarations/backend";

function getShortName() {
  return window.location.pathname.split('/').pop();
}

// Get the target URL from the backend
async function getTargetUrl(shortName) {
  try {
      const response = await backend.getLink(shortName);
      if (!response) throw new Error('Network response was not ok');
      return response;
  } catch (error) {
      console.error('Error:', error);
      return null;
  }
}

// Perform the redirect
async function performRedirect() {
  const shortName = getShortName();
  console.log('shortName', shortName);
  const targetUrl = await getTargetUrl(shortName);
  
  if (targetUrl && targetUrl.length > 0) {
      backend.incrementClickCount(shortName);
      console.log('targetUrl', targetUrl);
      let _targetObj = targetUrl[0];

      // Redirect to the target URL
      window.location.href = _targetObj.targetUrl;
  } else {
      document.getElementById('message').innerHTML = '<h1>Error</h1><p>Invalid or expired link.</p>';
  }
}

// Redirect on page load
window.onload = performRedirect;

// Manual redirect
document.getElementById('manual-redirect').onclick = (e) => {
  e.preventDefault();
  performRedirect();
};