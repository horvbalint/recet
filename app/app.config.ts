export default defineAppConfig({
  nebula: {
    nebSelect: {
      // Faking the type so that appConfig.nebula.nebSelect.emptyValue is not type as () => undefined or nullish
      emptyValue: (() => undefined) as any as null,
    },
  },
})
