// The slides of the deck, settled in the plugin's init, before Reveal lays them out: on a phone held
// upright Reveal then builds its scroll view, which wraps each slide in a page of its own, and a slide
// taken out or added later leaves an empty page that breaks the scrolling (fragments, lazy pictures).
//
// Teacher slides (class .teacher, e.g. the corrections of exercises): taken out of the deck for students.
// ?teacher in the address keeps them, and this browser remembers it (so the speaker view, another window,
// shows the same slides); ?teacher=off forgets it. They stay in the page source: hidden, not secret.
//
// References: a list taller than the slide is split over several slides with the same title and a page
// count ("References 1/2"), instead of one scrolling slide; measured again when the web fonts are loaded.
window.RevealKeynoteDeck = function () {
  function teacher() {
    const KEY = "keynote-teacher", q = new URLSearchParams(location.search);
    let on = false;
    try {
      if (q.has("teacher")) q.get("teacher") === "off" ? localStorage.removeItem(KEY) : localStorage.setItem(KEY, "1");
      on = localStorage.getItem(KEY) === "1";
    } catch (e) {
      on = q.has("teacher") && q.get("teacher") !== "off";
    }
    if (on) document.documentElement.classList.add("teacher-mode");
    else document.querySelectorAll(".reveal .slides section.teacher").forEach(s => s.remove());
  }

  function references(deck) {
    const refs = document.querySelector(".reveal .slides section #refs");
    if (refs === null) return;
    const slide = refs.closest("section");
    const entries = Array.from(refs.querySelectorAll(":scope > .csl-entry"));
    if (entries.length < 2) return;
    const width = deck.getConfig().width || 1280, height = deck.getConfig().height || 720;
    let pages = [slide];

    // the entries in groups that each fit on a slide, measured on the first page shown at its size, hidden
    function measure() {
      entries.forEach(entry => refs.appendChild(entry));
      const saved = slide.getAttribute("style");
      slide.style.cssText += `;display:block;visibility:hidden;width:${width}px;height:${height}px;overflow:visible`;
      const box = slide.getBoundingClientRect(), scale = box.height / height || 1;
      const top = e => (e.getBoundingClientRect().top - box.top) / scale;
      const bottom = e => (e.getBoundingClientRect().bottom - box.top) / scale;
      const start = top(entries[0]), limit = height - 16, groups = [[]];
      let offset = 0;
      entries.forEach(entry => {
        if (groups[groups.length - 1].length && bottom(entry) - offset > limit) {
          groups.push([]);
          offset = top(entry) - start;
        }
        groups[groups.length - 1].push(entry);
      });
      if (saved === null) slide.removeAttribute("style"); else slide.setAttribute("style", saved);
      return groups;
    }

    // as many pages as groups: the copies of the first page after it
    function paginate(n) {
      pages.slice(n).forEach(page => page.remove());
      pages = pages.slice(0, n);
      while (pages.length < n) {
        const page = slide.cloneNode(true);
        page.id = `${slide.id}-${pages.length + 1}`;
        page.classList.remove("present", "past", "future");
        page.removeAttribute("style");
        page.removeAttribute("hidden");
        page.removeAttribute("aria-hidden");
        page.querySelectorAll("aside.notes").forEach(notes => notes.remove());
        page.querySelector("#refs").removeAttribute("id");
        page.querySelectorAll(".csl-entry").forEach(entry => entry.remove());
        pages[pages.length - 1].after(page);
        pages.push(page);
      }
      if (n > 1) slide.classList.remove("scrollable");
    }

    // the groups on the pages, with the page count in the titles
    function fill(groups) {
      groups.forEach((group, i) => {
        const list = i === 0 ? refs : pages[i].querySelector(".csl-bib-body");
        group.forEach(entry => list.appendChild(entry));
      });
      pages.forEach((page, i) => {
        page.querySelectorAll(".refs-page").forEach(span => span.remove());
        const title = page.querySelector("h1, h2");
        if (title !== null && pages.length > 1) title.insertAdjacentHTML("beforeend", ` <span class="refs-page">${i + 1}/${pages.length}</span>`);
      });
    }

    const groups = measure();
    paginate(groups.length);
    fill(groups);

    // With the web fonts the lines may wrap differently: measure again. The scroll view has a page for
    // each slide, so there the slides stay and the entries move between them (more groups than slides:
    // the last slide takes the rest); in the slide view, slides are added or taken out.
    const again = () => {
      let groups = measure();
      if (groups.length !== pages.length && deck.isScrollView && deck.isScrollView()) {
        if (groups.length < pages.length) groups = groups.concat(Array.from({ length: pages.length - groups.length }, () => []));
        else groups = groups.slice(0, pages.length - 1).concat([groups.slice(pages.length - 1).flat()]);
        fill(groups);
        return;
      }
      if (groups.length === pages.length) { fill(groups); return; }
      const at = deck.getIndices();
      paginate(groups.length);
      fill(groups);
      deck.sync();
      deck.slide(at.h, at.v, at.f);
    };
    deck.on("ready", () => {
      if (document.fonts && document.fonts.status !== "loaded") document.fonts.ready.then(again);
    });
  }

  // The slide menu was built from the slides as they were: take out the items of the slides taken out,
  // add one for each page of the references, and number them again
  function syncMenu(deck, before) {
    const items = Array.from(document.querySelectorAll(".slide-menu-wrapper li.slide-menu-item[data-slide-h]"));
    if (items.length === 0) return;
    const index = new Map(deck.getHorizontalSlides().map((s, h) => [s.id, h]));
    let n = 0;
    items.forEach(item => {
      const id = before[+item.dataset.slideH];
      if (!index.has(id)) { item.remove(); return; }
      item.dataset.slideH = index.get(id);
      item.dataset.item = ++n;
      const title = item.querySelector(".slide-menu-item-title") || item;
      const pages = Array.from(document.querySelectorAll(`.reveal .slides section[id^="${CSS.escape(id)}-"] .refs-page`));
      if (!pages.length) return;
      const base = title.textContent.trim();
      title.textContent = `${base} 1/${pages.length + 1}`;
      let last = item;
      pages.forEach((span, i) => {
        const copy = item.cloneNode(true);
        copy.classList.remove("active", "past", "future");
        copy.dataset.slideH = index.get(span.closest("section").id);
        copy.dataset.item = ++n;
        (copy.querySelector(".slide-menu-item-title") || copy).textContent = `${base} ${i + 2}/${pages.length + 1}`;
        copy.addEventListener("click", () => deck.slide(+copy.dataset.slideH));
        last.after(copy);
        last = copy;
      });
    });
  }

  return {
    id: "RevealKeynoteDeck",
    init: deck => {
      const before = Array.from(document.querySelectorAll(".reveal .slides > section")).map(s => s.id);
      teacher();
      references(deck);
      deck.on("ready", () => syncMenu(deck, before));
    },
  };
};
