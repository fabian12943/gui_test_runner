const TYPE_SELECTION_ELEMENT = document.getElementById('type-selection')
const STATE_SELECTION_ELEMENT = document.getElementById('state-selection')
const INPUT_SEARCH_ELEMENT = document.getElementById('input-search')
const INPUT_SEARCH_DELAY = 300

up.observe(TYPE_SELECTION_ELEMENT, () => {
    filterExamples()
})

up.observe(STATE_SELECTION_ELEMENT, () => {
    filterExamples()
})

up.observe(INPUT_SEARCH_ELEMENT, { delay: INPUT_SEARCH_DELAY },  () => {
    filterExamples()
})

up.compiler('.example-list--entry', { batch: true }, (examples) => {
    filterExamples(examples)
})

function addExampleType(exampleType) {
    const type_options = [...TYPE_SELECTION_ELEMENT.options].map(type => type.value)
    if (!type_options.includes(exampleType)) {
        const opt = document.createElement('option');
        opt.classList.add('specific-option')
        opt.value = exampleType;
        opt.innerHTML = exampleType.charAt(0).toUpperCase() + exampleType.slice(1);
        TYPE_SELECTION_ELEMENT.appendChild(opt);
    }
}

function filterExamples(examples = null) {
    examples = examples || Array.from(document.querySelectorAll('.example-list--entry'))

    const examplesToDisplay = filterByType(examples)
                                .filter(filterByStatus)
                                .filter(filterByQuery);

    examples.forEach(e => e.classList.add('hidden'))
    examplesToDisplay.forEach(e => e.classList.remove('hidden'))
}

function filterByType(exampleEntries) {
    const type = TYPE_SELECTION_ELEMENT.value
    if (type === 'all') {
        return exampleEntries
    } else {
        return exampleEntries.filter(e => e.getAttribute('example-type') === type)
    }
}

function filterByStatus(exampleEntries) {
    const state = STATE_SELECTION_ELEMENT.value
    if (state === 'all') {
        return exampleEntries
    } else {
        return exampleEntries.filter(e => e.getAttribute('example-status') === state)
    }
}

function filterBySearchQuery(exampleEntries) {
    const query = INPUT_SEARCH_ELEMENT.value.trim().toLowerCase()
    if (query === '') {
        return exampleEntries
    } else {
        return exampleEntries.filter(element => {
            return JSON.parse(element.dataset.search).find(value => {
                return !!value.toLowerCase().includes(query);
            });
        })
    }
}
