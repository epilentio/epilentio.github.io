function copyToClipboard(textToCopy, buttonElement) {
  navigator.clipboard.writeText(textToCopy)
    .then(() => {
      const tooltip = buttonElement.parentElement;
      const copyIcon = buttonElement.querySelector('.copy-icon');
      const checkIcon = buttonElement.querySelector('.copy-icon-success');

      tooltip.setAttribute('data-tip', 'Copied!');
      copyIcon.classList.add('hidden');
      checkIcon.classList.remove('hidden');

      setTimeout(() => {
        tooltip.setAttribute('data-tip', 'Copy to clipboard');
        copyIcon.classList.remove('hidden');
        checkIcon.classList.add('hidden');
      }, 2000);
    })
    .catch(err => {
      console.error('Failed to copy: ', err);
    });
}
