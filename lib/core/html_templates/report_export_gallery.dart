/// Galeria de fotos no HTML **exportado** (JavaScript habilitado no navegador).
///
/// No app, [ReportPhotoLinks.prepareInAppHtml] remove o lightbox CSS e usa
/// `sfphoto://` + visualizador nativo — este script não roda com `sf-in-app`.
abstract final class ReportExportGallery {
  static final _hasPhotos = RegExp(r'<img\b[^>]*\bdata-sf-photo=');

  static String inject(String html) {
    if (!_hasPhotos.hasMatch(html)) return html;
    if (!html.contains('</body>')) return html;
    return html.replaceFirst('</body>', '$_markup$_script</body>');
  }

  static const _markup = '''
<div id="sf-export-gallery" class="sf-export-gallery" hidden aria-hidden="true">
  <button type="button" class="sf-export-gallery-close" aria-label="Fechar">×</button>
  <button type="button" class="sf-export-gallery-prev" aria-label="Foto anterior">‹</button>
  <button type="button" class="sf-export-gallery-next" aria-label="Próxima foto">›</button>
  <figure class="sf-export-gallery-figure">
    <img class="sf-export-gallery-img" alt="">
    <figcaption class="sf-export-gallery-caption"></figcaption>
  </figure>
</div>
''';

  static const _script = '''
<script>
(function () {
  if (document.documentElement.classList.contains('sf-in-app')) return;
  var photos = Array.prototype.slice.call(
    document.querySelectorAll('img[data-sf-photo]')
  );
  if (!photos.length) return;

  document.querySelectorAll('.sf-lb-toggle').forEach(function (el) {
    el.parentNode && el.parentNode.removeChild(el);
  });

  var overlay = document.getElementById('sf-export-gallery');
  if (!overlay) return;
  var imgEl = overlay.querySelector('.sf-export-gallery-img');
  var captionEl = overlay.querySelector('.sf-export-gallery-caption');
  var current = 0;

  function show(index) {
    current = (index + photos.length) % photos.length;
    var photo = photos[current];
    imgEl.src = photo.getAttribute('src') || '';
    imgEl.alt = photo.getAttribute('alt') || '';
    captionEl.textContent = photo.getAttribute('alt') || '';
    overlay.hidden = false;
    overlay.setAttribute('aria-hidden', 'false');
    overlay.classList.add('is-open');
    document.body.classList.add('sf-export-gallery-open');
  }

  function close() {
    overlay.classList.remove('is-open');
    overlay.hidden = true;
    overlay.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('sf-export-gallery-open');
    imgEl.removeAttribute('src');
  }

  overlay.querySelector('.sf-export-gallery-close').addEventListener('click', close);
  overlay.querySelector('.sf-export-gallery-prev').addEventListener('click', function () {
    show(current - 1);
  });
  overlay.querySelector('.sf-export-gallery-next').addEventListener('click', function () {
    show(current + 1);
  });
  overlay.addEventListener('click', function (event) {
    if (event.target === overlay) close();
  });

  document.addEventListener('keydown', function (event) {
    if (overlay.hidden) return;
    if (event.key === 'Escape') close();
    if (event.key === 'ArrowLeft') show(current - 1);
    if (event.key === 'ArrowRight') show(current + 1);
  });

  photos.forEach(function (photo, index) {
    photo.style.cursor = 'pointer';
    photo.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      show(index);
    });
  });
})();
</script>
''';
}
