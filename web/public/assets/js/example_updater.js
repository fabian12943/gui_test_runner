up.fragment.config.navigateOptions.solo = false

up.compiler('.overview', (element) => {
    const EVT_SOURCE = new EventSource('/stream')
    const UPDATE_INTERVAL_IN_MILLISECONDS = 1000

    let examplesToAdd = []
    let examplesToUpdate = {}

    let throttledUpdateReport = _.throttle(updateReport, UPDATE_INTERVAL_IN_MILLISECONDS)

    EVT_SOURCE.addEventListener('start_of_test_suite', (eventMessage) => {
        let data = JSON.parse(eventMessage.data)
        let rerun = data.rerun
        console.log("Test Suite started! (Rerun: " + rerun + ")")
        if (rerun === 'false') {
            document.querySelectorAll(".example-list--entry").forEach(el => el.remove())
            document.querySelectorAll("#type-selection .specific-option").forEach(el => el.remove())
        }
    })

    EVT_SOURCE.addEventListener('end_of_test_suite', () => {
        throttledUpdateReport()
    })

    EVT_SOURCE.addEventListener('new_example', (eventMessage) => {
        let data = JSON.parse(eventMessage.data)
        examplesToAdd.push(data.spec_id)
        addExampleType(data.example_type)
        throttledUpdateReport()
    })

    EVT_SOURCE.addEventListener('update_example', (eventMessage) => {
        let data = JSON.parse(eventMessage.data)
        examplesToUpdate[data.spec_id] = data.status;
        throttledUpdateReport()
    })

    function updateReport() {
        addExamples()
        updateExamples()
        updateProgress()
    }

    function addExamples() {
        if (examplesToAdd.length > 0) {
            up.render({ target: `.examples-list .example-list--entries:after`,
                        url: `/examples/list/selection`,
                        method: 'post',
                        params: { spec_ids: JSON.stringify(examplesToAdd) }
                      })
            examplesToAdd = []
        }
    }

    function updateExamples() {
        for (let spec_id in examplesToUpdate) {
            const example_entry_id = spec_id + "-entry"
            const example_entry_element = document.getElementById(example_entry_id)
            if (example_entry_element !== null) {
                example_entry_element.setAttribute("example-status", examplesToUpdate[spec_id])
                filterExamples([example_entry_element])
                delete examplesToUpdate[spec_id]
            }

            const example_results_id = spec_id + "-results"
            const example_results_element = document.getElementById(example_results_id)
            if (example_results_element !== null) {
                const results_target = "#" + example_results_id
                up.render({
                    target: results_target,
                    url: `/examples/${spec_id}/results`
                })
            }
        }
    }

    function updateProgress() {
        up.render({ target: '.test-suite-progress', url: '/test_progress' })
    }
})

up.compiler('.source-code', function(element) {
    Prism.hooks.add("before-sanity-check", function (env) {
        env.code = env.element.innerText;
    });
    Prism.highlightElement(element)
})
