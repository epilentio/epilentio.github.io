function copyToClipboard(textToCopy, buttonElement) {
  navigator.clipboard.writeText(textToCopy)
    .then(() => {
      const originalText = buttonElement.textContent;
      buttonElement.textContent = 'Copied!';
      setTimeout(() => {
        buttonElement.textContent = originalText;
      }, 2000);
    })
    .catch(err => {
      console.error('Failed to copy: ', err);
    });
}
